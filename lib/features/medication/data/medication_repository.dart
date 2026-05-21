import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/tables/catalog_items.dart';
import '../../../core/database/tables/schedules.dart';
import '../../../core/notifications/medication_notification_manager.dart';

/// 약 + 카탈로그 항목 + 해당 약의 스케줄들을 한 묶음으로 노출.
///
/// Phase 2B: `catalog` 필드 추가. catalogItemId가 set이면 catalog가 채워짐.
/// 카탈로그 메타(아이콘/색상/이름)는 catalog 우선, 없으면 tracked로 폴백.
class TrackedMedicationWithSchedules {
  const TrackedMedicationWithSchedules({
    required this.medication,
    required this.schedules,
    this.catalog,
  });

  final TrackedMedication medication;

  /// medication.catalogItemId가 set일 때 LEFT JOIN으로 채워짐. seed 항목이면
  /// 큐레이션된 iconKey/colorHex 활용 가능.
  final CatalogItem? catalog;

  final List<Schedule> schedules;

  /// "HH:mm" 시각 리스트 (오름차순).
  List<String> get times {
    final list = schedules.map((s) => s.timeOfDay).toList()..sort();
    return list;
  }

  /// 첫 스케줄 기준 repeat (모든 스케줄이 동일하다는 전제).
  RepeatKind get repeatKind =>
      schedules.isEmpty ? RepeatKind.daily : schedules.first.repeatKind;

  /// 첫 스케줄 기준 사전 알림 분 (모든 스케줄이 동일하다는 전제). null이면 OFF.
  int? get remindBeforeMinutes =>
      schedules.isEmpty ? null : schedules.first.remindBeforeMinutes;

  // ── 표시용 헬퍼 (catalog 우선 → tracked 폴백) ──
  String get displayName => catalog?.name ?? medication.name;
  String? get displayCategory => catalog?.category ?? medication.category;
  String? get displayDosage => medication.dosage ?? catalog?.defaultDosage;
  String? get displayUnit => medication.unit ?? catalog?.defaultUnit;
  String? get displayShape => catalog?.shape ?? medication.shape;
  String? get displayColorHex => catalog?.colorHex ?? medication.colorHex;
  String? get displayIconKey => catalog?.iconKey ?? medication.iconKey;

  /// 알람 활성 schedule이 1개 이상.
  bool get hasAlarm => schedules.isNotEmpty;
}

/// 신규/수정 시 입력 폼.
class TrackedMedicationDraft {
  const TrackedMedicationDraft({
    required this.name,
    required this.category,
    required this.times,
    required this.repeatKind,
    this.dosage,
    this.unit,
    this.daysOfWeekMask,
    this.intervalDays,
    this.memo,
    this.remindBeforeMinutes,
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

  /// 본 알림 N분 전 사전 알림. null/0이면 OFF.
  /// 약 1개 = 모든 스케줄에 동일 적용.
  final int? remindBeforeMinutes;
}

class TrackedMedicationRepository {
  TrackedMedicationRepository(this._db, this._notif);

  final AppDatabase _db;
  final MedicationNotificationManager _notif;
  static const _uuid = Uuid();

  /// 활성(미아카이브) 약 전체 + 카탈로그 + 스케줄을 실시간 스트림으로.
  ///
  /// join을 써서 watch가 tracked_medications + catalog_items + schedules
  /// 세 테이블 모두 추적. catalogItemId가 null인 행은 catalog가 null로 join.
  Stream<List<TrackedMedicationWithSchedules>> watchAll() {
    final query = _db.select(_db.trackedMedications).join([
      leftOuterJoin(
        _db.catalogItems,
        _db.catalogItems.id.equalsExp(_db.trackedMedications.catalogItemId),
      ),
      leftOuterJoin(
        _db.schedules,
        _db.schedules.medicationId.equalsExp(_db.trackedMedications.id) &
            _db.schedules.enabled.equals(true),
      ),
    ])
      ..where(_db.trackedMedications.archived.equals(false))
      ..orderBy([OrderingTerm(expression: _db.trackedMedications.name)]);

    return query.watch().map((rows) {
      final medsById = <int, TrackedMedication>{};
      final catalogByMedId = <int, CatalogItem?>{};
      final schedsById = <int, List<Schedule>>{};
      for (final row in rows) {
        final med = row.readTable(_db.trackedMedications);
        medsById.putIfAbsent(med.id, () => med);
        catalogByMedId.putIfAbsent(
            med.id, () => row.readTableOrNull(_db.catalogItems));
        final sched = row.readTableOrNull(_db.schedules);
        if (sched != null) {
          (schedsById[med.id] ??= []).add(sched);
        }
      }
      return [
        for (final m in medsById.values)
          TrackedMedicationWithSchedules(
            medication: m,
            catalog: catalogByMedId[m.id],
            schedules: schedsById[m.id] ?? const [],
          ),
      ];
    });
  }

  /// 단일 약 + 카탈로그 + 스케줄 스트림. join으로 세 테이블 추적.
  Stream<TrackedMedicationWithSchedules?> watchById(int id) {
    final query = _db.select(_db.trackedMedications).join([
      leftOuterJoin(
        _db.catalogItems,
        _db.catalogItems.id.equalsExp(_db.trackedMedications.catalogItemId),
      ),
      leftOuterJoin(
        _db.schedules,
        _db.schedules.medicationId.equalsExp(_db.trackedMedications.id),
      ),
    ])..where(_db.trackedMedications.id.equals(id));

    return query.watch().map((rows) {
      if (rows.isEmpty) return null;
      final med = rows.first.readTable(_db.trackedMedications);
      final catalog = rows.first.readTableOrNull(_db.catalogItems);
      final scheds = <Schedule>[
        for (final r in rows)
          if (r.readTableOrNull(_db.schedules) != null)
            r.readTable(_db.schedules),
      ];
      return TrackedMedicationWithSchedules(
        medication: med,
        catalog: catalog,
        schedules: scheds,
      );
    });
  }

  Future<TrackedMedicationWithSchedules?> getById(int id) async {
    final med = await (_db.select(_db.trackedMedications)
          ..where((m) => m.id.equals(id)))
        .getSingleOrNull();
    if (med == null) return null;
    final scheds = await (_db.select(_db.schedules)
          ..where((s) => s.medicationId.equals(id)))
        .get();
    final catalog = med.catalogItemId == null
        ? null
        : await (_db.select(_db.catalogItems)
              ..where((c) => c.id.equals(med.catalogItemId!)))
            .getSingleOrNull();
    return TrackedMedicationWithSchedules(
      medication: med,
      catalog: catalog,
      schedules: scheds,
    );
  }

  /// 신규 등록. 트랜잭션으로:
  ///  1) catalog_items에 source='user' 항목 자동 생성 (Phase 3 UI 도입 전 임시 경로)
  ///  2) tracked_medications insert (catalog_item_id FK 자동 link)
  ///  3) schedules 동시 insert
  ///  4) 알림 동기화
  ///
  /// Phase 3에서 등록 플로우가 catalog 검색을 지원하면 이 메서드는 [catalogItemId]
  /// 인자를 받아 기존 catalog 항목을 재사용하도록 분기 추가 예정.
  Future<int> insertWithSchedules(TrackedMedicationDraft draft) async {
    final catalogId = _uuid.v4();
    final medId = await _db.transaction(() async {
      // 1) catalog_items에 source='user' 자동 등록.
      // 사용자가 직접 입력한 이름/카테고리/메타를 catalog에 보존 → 다음 등록 시
      // 검색으로 재발견 가능.
      await _db.into(_db.catalogItems).insert(
            CatalogItemsCompanion.insert(
              id: catalogId,
              name: draft.name,
              category: draft.category,
              defaultDosage: Value(draft.dosage),
              defaultUnit: Value(draft.unit),
              tagsJson: Value(jsonEncode(const <String>[])),
              source: const Value(CatalogSource.user),
            ),
          );

      // 2) tracked_medications insert with FK.
      final id = await _db.into(_db.trackedMedications).insert(
            TrackedMedicationsCompanion.insert(
              catalogItemId: Value(catalogId),
              name: draft.name,
              category: Value(draft.category),
              dosage: Value(draft.dosage),
              unit: Value(draft.unit),
              memo: Value(draft.memo),
            ),
          );

      // 3) schedules.
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
                remindBeforeMinutes: Value(draft.remindBeforeMinutes),
              ),
            );
      }
      return id;
    });
    await _notif.syncSchedulesFor(medId);
    return medId;
  }

  /// 기존 약 수정. 스케줄은 통째로 교체 + 알림 재동기화.
  /// 연결된 catalog_item (source='user'인 경우만)도 이름/카테고리/dosage 동기화.
  Future<void> updateWithSchedules(int id, TrackedMedicationDraft draft) async {
    await _db.transaction(() async {
      // tracked 업데이트.
      await (_db.update(_db.trackedMedications)..where((m) => m.id.equals(id)))
          .write(
        TrackedMedicationsCompanion(
          name: Value(draft.name),
          category: Value(draft.category),
          dosage: Value(draft.dosage),
          unit: Value(draft.unit),
          memo: Value(draft.memo),
          updatedAt: Value(DateTime.now()),
        ),
      );

      // 연결된 catalog_item (source='user') 동기화. seed 항목은 보호.
      final tracked = await (_db.select(_db.trackedMedications)
            ..where((m) => m.id.equals(id)))
          .getSingleOrNull();
      final catalogId = tracked?.catalogItemId;
      if (catalogId != null) {
        final catalog = await (_db.select(_db.catalogItems)
              ..where((c) => c.id.equals(catalogId)))
            .getSingleOrNull();
        if (catalog != null && catalog.source == CatalogSource.user) {
          await (_db.update(_db.catalogItems)
                ..where((c) => c.id.equals(catalogId)))
              .write(CatalogItemsCompanion(
            name: Value(draft.name),
            category: Value(draft.category),
            defaultDosage: Value(draft.dosage),
            defaultUnit: Value(draft.unit),
          ));
        }
      }

      // schedules 교체.
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
                remindBeforeMinutes: Value(draft.remindBeforeMinutes),
              ),
            );
      }
    });
    await _notif.syncSchedulesFor(id);
  }

  /// hard delete. cascade로 schedules/intake_logs 같이 사라짐. 알림도 먼저 취소.
  ///
  /// catalog_item은 별도 lifecycle (다른 tracked가 같은 catalog를 가리킬 수
  /// 있으므로 자동 삭제하지 않음). source='user' + 더 이상 참조 없는 항목
  /// 정리는 후속 작업.
  Future<void> delete(int id) async {
    // cascade로 schedules가 사라지기 전에 알림 취소 (id 매핑 위해).
    await _notif.cancelForMedication(id);
    await (_db.delete(_db.trackedMedications)..where((m) => m.id.equals(id)))
        .go();
  }

  /// 알람 on/off (모든 스케줄 enabled toggle) + 알림 동기화.
  Future<void> setAlarmEnabled(int medicationId, bool enabled) async {
    await (_db.update(_db.schedules)
          ..where((s) => s.medicationId.equals(medicationId)))
        .write(SchedulesCompanion(enabled: Value(enabled)));
    await _notif.syncSchedulesFor(medicationId);
  }
}
