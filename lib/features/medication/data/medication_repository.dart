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

  // ── 표시용 헬퍼 (Phase 2C: catalog만이 메타 SSOT. catalog NULL은 legacy) ──
  /// catalog가 끊긴 legacy tracked의 폴백 텍스트.
  static const _missingNameFallback = '(이름 없음)';

  String get displayName => catalog?.name ?? _missingNameFallback;
  String? get displayCategory => catalog?.category;
  String? get displayDosage => medication.customDosage ?? catalog?.defaultDosage;
  String? get displayUnit => medication.customUnit ?? catalog?.defaultUnit;
  String? get displayShape => catalog?.shape;
  String? get displayColorHex => catalog?.colorHex;
  String? get displayIconKey => catalog?.iconKey;

  /// 알람 활성 schedule이 1개 이상.
  bool get hasAlarm => schedules.isNotEmpty;
}

/// 신규/수정 시 입력 폼.
///
/// Phase 2C: 이름/카테고리/모양/색상/아이콘은 catalog가 SSOT이므로 [catalogItemId]만
/// 받음. 호출자가 사전에 [TrackedMedicationRepository.resolveOrCreateCatalog]로
/// catalog id를 확보한 뒤 Draft에 채워 전달.
class TrackedMedicationDraft {
  const TrackedMedicationDraft({
    required this.catalogItemId,
    required this.times,
    required this.repeatKind,
    this.customDosage,
    this.customUnit,
    this.daysOfWeekMask,
    this.intervalDays,
    this.memo,
    this.remindBeforeMinutes,
  });

  /// 필수: catalog_items.id (seed slug 또는 user UUID).
  final String catalogItemId;

  /// catalog.defaultDosage override. null이면 catalog 값 사용.
  final String? customDosage;

  /// catalog.defaultUnit override. null이면 catalog 값 사용.
  final String? customUnit;

  /// "HH:mm" list. 비어 있으면 필요시 복용 (PRN).
  final List<String> times;
  final RepeatKind repeatKind;
  final int? daysOfWeekMask;
  final int? intervalDays;
  final String? memo;

  /// 본 알림 N분 전 사전 알림. null/0이면 OFF.
  /// 약 1개 = 모든 스케줄에 동일 적용.
  final int? remindBeforeMinutes;
}

/// catalog 검색/생성을 위한 입력. UI step2(name/category 입력)에서
/// [TrackedMedicationRepository.resolveOrCreateCatalog]에 전달.
class CatalogResolveInput {
  const CatalogResolveInput({
    required this.name,
    required this.category,
    this.defaultDosage,
    this.defaultUnit,
    this.shape,
    this.colorHex,
    this.iconKey,
  });

  final String name;
  final String category;
  final String? defaultDosage;
  final String? defaultUnit;
  final String? shape;
  final String? colorHex;
  final String? iconKey;
}

/// catalog ↔ tracked 1:1 제약 위반(같은 catalog로 재등록 시도) 시 발생.
/// 호출자(add_flow)가 catch해서 “시각 추가” 모드로 분기.
class DuplicateCatalogTrackedException implements Exception {
  const DuplicateCatalogTrackedException(this.existingMedicationId);

  /// 이미 등록되어 있는 tracked의 id — 편집 모드 라우팅에 사용.
  final int existingMedicationId;

  @override
  String toString() =>
      'DuplicateCatalogTrackedException(existingId=$existingMedicationId)';
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
      // Phase 2C: tracked.name 컬럼 제거 → catalog.name으로 정렬.
      // catalog가 NULL인 legacy는 정렬 끝(NULL은 SQLite에서 작은 값으로 정렬).
      ..orderBy([OrderingTerm(expression: _db.catalogItems.name)]);

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

  /// catalog 단일 fetch — 등록 플로우에서 override 비교용으로 사용.
  Future<CatalogItem?> getCatalogById(String id) {
    return (_db.select(_db.catalogItems)..where((c) => c.id.equals(id)))
        .getSingleOrNull();
  }

  /// 주어진 catalog로 이미 등록된 tracked가 있는지 조회 (catalog ↔ tracked 1:1).
  /// 등록 플로우에서 step2 catalog 선택 후 호출 — 있으면 “시각 추가” 분기.
  Future<TrackedMedicationWithSchedules?> findTrackedByCatalogId(
      String catalogId) async {
    final rows = await (_db.select(_db.trackedMedications).join([
      leftOuterJoin(
        _db.catalogItems,
        _db.catalogItems.id.equalsExp(_db.trackedMedications.catalogItemId),
      ),
      leftOuterJoin(
        _db.schedules,
        _db.schedules.medicationId.equalsExp(_db.trackedMedications.id),
      ),
    ])
          ..where(_db.trackedMedications.catalogItemId.equals(catalogId) &
              _db.trackedMedications.archived.equals(false)))
        .get();

    if (rows.isEmpty) return null;
    final med = rows.first.readTable(_db.trackedMedications);
    final catalog = rows.first.readTableOrNull(_db.catalogItems);
    final scheds = <Schedule>[
      for (final r in rows)
        if (r.readTableOrNull(_db.schedules) != null) r.readTable(_db.schedules),
    ];
    return TrackedMedicationWithSchedules(
      medication: med,
      catalog: catalog,
      schedules: scheds,
    );
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
  ///
  /// Phase 2C: public API. UI step2(name/category 입력 받음)에서 호출 후
  /// 반환된 id를 [TrackedMedicationDraft.catalogItemId]에 넣어 사용.
  /// 트랜잭션 외부 호출도 가능 — Drift가 implicit 트랜잭션 처리.
  Future<String> resolveOrCreateCatalog(CatalogResolveInput input) async {
    final existing = await (_db.select(_db.catalogItems)
          ..where((c) =>
              c.name.equals(input.name) & c.category.equals(input.category))
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
            name: input.name,
            category: input.category,
            defaultDosage: Value(input.defaultDosage),
            defaultUnit: Value(input.defaultUnit),
            shape: Value(input.shape),
            colorHex: Value(input.colorHex),
            iconKey: Value(input.iconKey),
            tagsJson: Value(jsonEncode(const <String>[])),
            source: const Value(CatalogSource.user),
          ),
        );
    return id;
  }

  Future<({int medicationId, List<int> scheduleIds})> insertWithSchedules(
    TrackedMedicationDraft draft,
  ) async {
    final result = await _db.transaction(() async {
      // catalog ↔ tracked 1:1 — 같은 catalog가 이미 있으면 caller가
      // updateWithSchedules로 분기하도록 명시적 throw.
      final existing = await (_db.select(_db.trackedMedications)
            ..where((m) =>
                m.catalogItemId.equals(draft.catalogItemId) &
                m.archived.equals(false)))
          .getSingleOrNull();
      if (existing != null) {
        throw DuplicateCatalogTrackedException(existing.id);
      }

      // 1) tracked_medications insert — 메타는 catalog FK로 위임.
      final id = await _db.into(_db.trackedMedications).insert(
            TrackedMedicationsCompanion.insert(
              catalogItemId: Value(draft.catalogItemId),
              customDosage: Value(draft.customDosage),
              customUnit: Value(draft.customUnit),
              memo: Value(draft.memo),
            ),
          );

      // 2) schedules.
      // startDate는 등록 시각 그대로 보존 — 시각 정보를 자르면 오늘 등록 시점
      // 이전의 슬롯들이 active로 잡혀 놓침으로 카운트되는 버그.
      final now = DateTime.now();
      // 시각 dedup — UI에서 막지만 방어. legacy draft에 중복 들어오는 경우도 케이스.
      final scheduleIds = <int>[];
      for (final t in draft.times.toSet()) {
        final sid = await _db.into(_db.schedules).insert(
              SchedulesCompanion.insert(
                medicationId: id,
                timeOfDay: t,
                startDate: now,
                repeatKind: Value(draft.repeatKind),
                daysOfWeekMask: Value(draft.daysOfWeekMask),
                intervalDays: Value(draft.intervalDays),
                remindBeforeMinutes: Value(draft.remindBeforeMinutes),
              ),
            );
        scheduleIds.add(sid);
      }
      return (medicationId: id, scheduleIds: scheduleIds);
    });
    await _notif.syncSchedulesFor(result.medicationId);
    return result;
  }

  /// 기존 약 수정. 스케줄은 통째로 교체 + 알림 재동기화.
  ///
  /// Phase 2C: catalog FK 자체는 호출자가 [resolveOrCreateCatalog]로 사전 확정.
  /// 기존 catalog와 다른 id로 변경되면 relink 효과. 같으면 in-place 갱신.
  /// catalog 자체 mutate는 하지 않음(다른 tracked가 공유 가능).
  Future<List<int>> updateWithSchedules(
    int id,
    TrackedMedicationDraft draft,
  ) async {
    final scheduleIds = await _db.transaction(() async {
      // tracked 업데이트 (catalogItemId 포함 relink).
      await (_db.update(_db.trackedMedications)..where((m) => m.id.equals(id)))
          .write(
        TrackedMedicationsCompanion(
          catalogItemId: Value(draft.catalogItemId),
          customDosage: Value(draft.customDosage),
          customUnit: Value(draft.customUnit),
          memo: Value(draft.memo),
          updatedAt: Value(DateTime.now()),
        ),
      );

      // schedules 교체.
      await (_db.delete(_db.schedules)..where((s) => s.medicationId.equals(id)))
          .go();
      // insertWithSchedules와 동일 — startDate는 시각까지 보존.
      final now = DateTime.now();
      // 시각 dedup — UI에서 막지만 방어. legacy draft에 중복 들어오는 경우도 케이스.
      final sids = <int>[];
      for (final t in draft.times.toSet()) {
        final sid = await _db.into(_db.schedules).insert(
              SchedulesCompanion.insert(
                medicationId: id,
                timeOfDay: t,
                startDate: now,
                repeatKind: Value(draft.repeatKind),
                daysOfWeekMask: Value(draft.daysOfWeekMask),
                intervalDays: Value(draft.intervalDays),
                remindBeforeMinutes: Value(draft.remindBeforeMinutes),
              ),
            );
        sids.add(sid);
      }

      // relink로 이전 catalog가 고아 됐을 수 있음 → 정리.
      await _cleanupOrphanUserCatalogs();
      return sids;
    });
    await _notif.syncSchedulesFor(id);
    return scheduleIds;
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

      // Phase 2C: tracked.name 컬럼 제거 → catalog.name 조회로 snapshot 확보.
      // catalog가 끊긴 legacy면 빈 문자열 폴백.
      String? snapshotName;
      final catalogId = tracked.catalogItemId;
      if (catalogId != null) {
        final c = await (_db.select(_db.catalogItems)
              ..where((c) => c.id.equals(catalogId)))
            .getSingleOrNull();
        snapshotName = c?.name;
      }

      // 1) 이름 snapshot — 기존 intake_logs 전부에 적용 (이미 set된 건 덮어쓰지
      //    않도록 IS NULL 조건). 사용자가 같은 이름으로 여러 번 등록·삭제 반복
      //    시에도 가장 처음 삭제 시점 이름이 유지.
      await (_db.update(_db.intakeLogs)
            ..where((l) =>
                l.medicationId.equals(id) & l.medNameSnapshot.isNull()))
          .write(IntakeLogsCompanion(
        medNameSnapshot: Value(snapshotName),
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
