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
  ///  1) **dedupe**: 같은 (name, category)의 catalog 항목이 이미 있으면 재사용
  ///     (seed 우선 → user). 없으면 source='user' 새 항목 생성.
  ///  2) tracked_medications insert (catalog_item_id FK)
  ///  3) schedules 동시 insert
  ///  4) 알림 동기화
  ///
  /// catalog dedupe 이유: 같은 약을 반복 등록·삭제할 때마다 user catalog row가
  /// 무한정 늘어나는 걸 방지. 자동완성/검색에 동일 이름이 N번 노출되는 문제도
  /// 같이 해결.
  /// 더 이상 어떤 tracked도 참조하지 않는 user catalog 항목을 일괄 삭제.
  ///
  /// 트리거 케이스:
  /// - [updateWithSchedules]에서 catalog relink로 이전 catalog가 고아 됨
  /// - [delete]에서 tracked 사라지며 그 catalog가 다른 참조 없음
  /// - 과거 dedupe 도입 전 누적된 중복 user catalog
  ///
  /// seed 카탈로그는 절대 건드리지 않음 (curated, immutable).
  /// 반드시 transaction 안에서 호출.
  Future<void> _cleanupOrphanUserCatalogs() async {
    await _db.customStatement(
      'DELETE FROM catalog_items '
      'WHERE source = ${CatalogSource.user.index} '
      'AND id NOT IN ('
      '  SELECT catalog_item_id FROM tracked_medications '
      '  WHERE catalog_item_id IS NOT NULL'
      ')',
    );
  }

  /// 외부 호출용 — 앱 부팅 시점에 한 번 청소.
  Future<void> cleanupOrphanUserCatalogs() async {
    await _db.transaction(_cleanupOrphanUserCatalogs);
  }

  /// 같은 (medicationId, timeOfDay) 조합으로 여러 행이 존재하는 legacy 중복
  /// schedules를 정리. 가장 오래된 row만 남기고 나머지 삭제 (intake_logs는
  /// scheduleId setNull로 안전, 일부는 남은 schedule로 재정렬 안 됨 — 과거
  /// 기록이라 미수정).
  /// 앱 부팅 시 1회 호출.
  Future<void> cleanupDuplicateSchedules() async {
    await _db.customStatement(
      'DELETE FROM schedules '
      'WHERE id NOT IN ('
      '  SELECT MIN(id) FROM schedules '
      '  GROUP BY medication_id, time_of_day'
      ')',
    );
  }

  /// 같은 (name, category)의 catalog 항목이 있으면 id 반환, 없으면 user
  /// 카탈로그 생성 후 새 id 반환. dedupe + create 통합 헬퍼.
  /// 반드시 transaction 안에서 호출.
  Future<String> _resolveOrCreateCatalog(TrackedMedicationDraft draft) async {
    final existing = await (_db.select(_db.catalogItems)
          ..where((c) =>
              c.name.equals(draft.name) & c.category.equals(draft.category))
          ..orderBy([
            (c) => OrderingTerm(expression: c.source),
            (c) => OrderingTerm(expression: c.createdAt),
          ])
          ..limit(1))
        .getSingleOrNull();
    if (existing != null) return existing.id;

    final id = _uuid.v4();
    await _db.into(_db.catalogItems).insert(
          CatalogItemsCompanion.insert(
            id: id,
            name: draft.name,
            category: draft.category,
            defaultDosage: Value(draft.dosage),
            defaultUnit: Value(draft.unit),
            tagsJson: Value(jsonEncode(const <String>[])),
            source: const Value(CatalogSource.user),
          ),
        );
    return id;
  }

  Future<int> insertWithSchedules(TrackedMedicationDraft draft) async {
    final medId = await _db.transaction(() async {
      final catalogId = await _resolveOrCreateCatalog(draft);

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
      // 시각 dedup — UI에서 막지만 방어. legacy draft에 중복 들어오는 경우도 케이스.
      for (final t in draft.times.toSet()) {
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
  ///
  /// catalog는 mutate하지 않음 (다른 tracked가 같은 catalog를 공유할 수 있어
  /// 부작용 위험). 대신 (name, category)에 맞는 catalog를 dedupe하거나 새로
  /// 만들어 tracked의 FK만 갈아끼움. relink로 고아가 된 user catalog는
  /// [_cleanupOrphanUserCatalogs]가 같은 트랜잭션 안에서 정리.
  Future<void> updateWithSchedules(int id, TrackedMedicationDraft draft) async {
    await _db.transaction(() async {
      final catalogId = await _resolveOrCreateCatalog(draft);

      // tracked 업데이트 (catalogItemId 포함 relink).
      await (_db.update(_db.trackedMedications)..where((m) => m.id.equals(id)))
          .write(
        TrackedMedicationsCompanion(
          catalogItemId: Value(catalogId),
          name: Value(draft.name),
          category: Value(draft.category),
          dosage: Value(draft.dosage),
          unit: Value(draft.unit),
          memo: Value(draft.memo),
          updatedAt: Value(DateTime.now()),
        ),
      );

      // schedules 교체.
      await (_db.delete(_db.schedules)..where((s) => s.medicationId.equals(id)))
          .go();
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      // 시각 dedup — UI에서 막지만 방어. legacy draft에 중복 들어오는 경우도 케이스.
      for (final t in draft.times.toSet()) {
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

      // relink로 이전 catalog가 고아 됐을 수 있음 → 정리.
      await _cleanupOrphanUserCatalogs();
    });
    await _notif.syncSchedulesFor(id);
  }

  /// tracked + schedules 삭제. intake_logs는 **보존** (v6 setNull 정책):
  ///   1) 삭제 전 intake_logs의 medNameSnapshot에 tracked.name 복사 — 나중에
  ///      사용자가 "삭제된 약" 표시를 볼 수 있도록.
  ///   2) tracked 삭제 → schedules cascade 삭제, intake_logs는 setNull로 남음.
  ///   3) 알림 취소 (cascade로 schedules 사라지기 전에 id 매핑 위해 먼저).
  ///
  /// catalog_item은 별도 lifecycle (다른 tracked가 같은 catalog를 가리킬 수
  /// 있으므로 자동 삭제하지 않음). 단, 이 tracked가 참조하던 user catalog가
  /// 고아가 됐으면 같은 트랜잭션 안에서 [_cleanupOrphanUserCatalogs]가 제거.
  Future<void> delete(int id) async {
    // cascade로 schedules가 사라지기 전에 알림 취소 (id 매핑 위해).
    await _notif.cancelForMedication(id);

    await _db.transaction(() async {
      final tracked = await (_db.select(_db.trackedMedications)
            ..where((m) => m.id.equals(id)))
          .getSingleOrNull();
      if (tracked == null) return;

      // 1) 이름 snapshot — 기존 intake_logs 전부에 적용 (이미 set된 건 덮어쓰지
      //    않도록 IS NULL 조건). 사용자가 같은 이름으로 여러 번 등록·삭제 반복
      //    시에도 가장 처음 삭제 시점 이름이 유지.
      await (_db.update(_db.intakeLogs)
            ..where((l) =>
                l.medicationId.equals(id) & l.medNameSnapshot.isNull()))
          .write(IntakeLogsCompanion(
        medNameSnapshot: Value(tracked.name),
      ));

      // 2) tracked 삭제 — schedules cascade, intake_logs는 medication_id/
      //    schedule_id 둘 다 setNull.
      await (_db.delete(_db.trackedMedications)..where((m) => m.id.equals(id)))
          .go();

      // 3) 이 tracked가 참조하던 catalog가 고아 됐으면 정리.
      await _cleanupOrphanUserCatalogs();
    });
  }

  /// 알람 on/off (모든 스케줄 enabled toggle) + 알림 동기화.
  Future<void> setAlarmEnabled(int medicationId, bool enabled) async {
    await (_db.update(_db.schedules)
          ..where((s) => s.medicationId.equals(medicationId)))
        .write(SchedulesCompanion(enabled: Value(enabled)));
    await _notif.syncSchedulesFor(medicationId);
  }
}
