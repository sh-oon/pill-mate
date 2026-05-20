import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/tables/schedules.dart';
import '../../../core/notifications/medication_notification_manager.dart';

/// 약 + 해당 약의 스케줄들을 한 묶음으로 노출.
class MedicationWithSchedules {
  const MedicationWithSchedules({
    required this.medication,
    required this.schedules,
  });

  final Medication medication;
  final List<Schedule> schedules;

  /// "HH:mm" 시각 리스트 (오름차순).
  List<String> get times {
    final list = schedules.map((s) => s.timeOfDay).toList()..sort();
    return list;
  }

  /// 첫 스케줄 기준 repeat (모든 스케줄이 동일하다는 전제).
  RepeatKind get repeatKind =>
      schedules.isEmpty ? RepeatKind.daily : schedules.first.repeatKind;
}

/// 신규/수정 시 입력 폼.
class MedicationDraft {
  const MedicationDraft({
    required this.name,
    required this.category,
    required this.times,
    required this.repeatKind,
    this.dosage,
    this.unit,
    this.daysOfWeekMask,
    this.intervalDays,
    this.memo,
  });

  final String name;

  /// 'med' | 'sup'
  final String category;

  /// "HH:mm" list. 비어 있으면 필요시 복용 (PRN).
  final List<String> times;
  final RepeatKind repeatKind;
  final String? dosage;
  final String? unit;
  final int? daysOfWeekMask;
  final int? intervalDays;
  final String? memo;
}

class MedicationRepository {
  MedicationRepository(this._db, this._notif);

  final AppDatabase _db;
  final MedicationNotificationManager _notif;

  /// 활성(미아카이브) 약 전체 + 스케줄을 실시간 스트림으로.
  ///
  /// join을 써서 watch가 medications + schedules 두 테이블 모두 추적.
  /// (단일 테이블 watch는 schedule만 바뀐 경우 누락 가능)
  Stream<List<MedicationWithSchedules>> watchAll() {
    final query = _db.select(_db.medications).join([
      leftOuterJoin(
        _db.schedules,
        _db.schedules.medicationId.equalsExp(_db.medications.id) &
            _db.schedules.enabled.equals(true),
      ),
    ])
      ..where(_db.medications.archived.equals(false))
      ..orderBy([OrderingTerm(expression: _db.medications.name)]);

    return query.watch().map((rows) {
      final medsById = <int, Medication>{};
      final schedsById = <int, List<Schedule>>{};
      for (final row in rows) {
        final med = row.readTable(_db.medications);
        medsById.putIfAbsent(med.id, () => med);
        final sched = row.readTableOrNull(_db.schedules);
        if (sched != null) {
          (schedsById[med.id] ??= []).add(sched);
        }
      }
      return [
        for (final m in medsById.values)
          MedicationWithSchedules(
            medication: m,
            schedules: schedsById[m.id] ?? const [],
          ),
      ];
    });
  }

  /// 단일 약 + 스케줄 스트림. join으로 두 테이블 추적.
  Stream<MedicationWithSchedules?> watchById(int id) {
    final query = _db.select(_db.medications).join([
      leftOuterJoin(
        _db.schedules,
        _db.schedules.medicationId.equalsExp(_db.medications.id),
      ),
    ])..where(_db.medications.id.equals(id));

    return query.watch().map((rows) {
      if (rows.isEmpty) return null;
      final med = rows.first.readTable(_db.medications);
      final scheds = <Schedule>[
        for (final r in rows)
          if (r.readTableOrNull(_db.schedules) != null)
            r.readTable(_db.schedules),
      ];
      return MedicationWithSchedules(medication: med, schedules: scheds);
    });
  }

  Future<MedicationWithSchedules?> getById(int id) async {
    final med = await (_db.select(_db.medications)
          ..where((m) => m.id.equals(id)))
        .getSingleOrNull();
    if (med == null) return null;
    final scheds = await (_db.select(_db.schedules)
          ..where((s) => s.medicationId.equals(id)))
        .get();
    return MedicationWithSchedules(medication: med, schedules: scheds);
  }

  /// 신규 등록. 트랜잭션으로 medication + schedules 동시 insert + 알림 동기화.
  Future<int> insertWithSchedules(MedicationDraft draft) async {
    final medId = await _db.transaction(() async {
      final id = await _db.into(_db.medications).insert(
            MedicationsCompanion.insert(
              name: draft.name,
              category: Value(draft.category),
              dosage: Value(draft.dosage),
              unit: Value(draft.unit),
              memo: Value(draft.memo),
            ),
          );
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      for (final t in draft.times) {
        await _db.into(_db.schedules).insert(
              SchedulesCompanion.insert(
                medicationId: id,
                timeOfDay: t,
                startDate: startOfToday,
                repeatKind: Value(draft.repeatKind),
                daysOfWeekMask: Value(draft.daysOfWeekMask),
                intervalDays: Value(draft.intervalDays),
              ),
            );
      }
      return id;
    });
    await _notif.syncSchedulesFor(medId);
    return medId;
  }

  /// 기존 약 수정. 스케줄은 통째로 교체 + 알림 재동기화.
  Future<void> updateWithSchedules(int id, MedicationDraft draft) async {
    await _db.transaction(() async {
      await (_db.update(_db.medications)..where((m) => m.id.equals(id))).write(
        MedicationsCompanion(
          name: Value(draft.name),
          category: Value(draft.category),
          dosage: Value(draft.dosage),
          unit: Value(draft.unit),
          memo: Value(draft.memo),
          updatedAt: Value(DateTime.now()),
        ),
      );
      await (_db.delete(_db.schedules)..where((s) => s.medicationId.equals(id)))
          .go();
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      for (final t in draft.times) {
        await _db.into(_db.schedules).insert(
              SchedulesCompanion.insert(
                medicationId: id,
                timeOfDay: t,
                startDate: startOfToday,
                repeatKind: Value(draft.repeatKind),
                daysOfWeekMask: Value(draft.daysOfWeekMask),
                intervalDays: Value(draft.intervalDays),
              ),
            );
      }
    });
    await _notif.syncSchedulesFor(id);
  }

  /// hard delete (cascade로 schedules/intake_logs 같이 사라짐). 알림도 먼저 취소.
  Future<void> delete(int id) async {
    // cascade로 schedules가 사라지기 전에 알림 취소 (id 매핑 위해).
    await _notif.cancelForMedication(id);
    await (_db.delete(_db.medications)..where((m) => m.id.equals(id))).go();
  }

  /// 알람 on/off (모든 스케줄 enabled toggle) + 알림 동기화.
  Future<void> setAlarmEnabled(int medicationId, bool enabled) async {
    await (_db.update(_db.schedules)
          ..where((s) => s.medicationId.equals(medicationId)))
        .write(SchedulesCompanion(enabled: Value(enabled)));
    await _notif.syncSchedulesFor(medicationId);
  }
}
