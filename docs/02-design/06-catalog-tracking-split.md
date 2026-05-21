---
template: design
version: 1.0
feature: catalog-tracking-split
date: 2026-05-21
author: gamja (assisted)
project: pill-mate
platform: Flutter (iOS + Android)
status: Draft
depends_on:
  - docs/01-plan/features/catalog-tracking-split.plan.md
---

# 06 — 카탈로그 / 트래킹 / 알람 3-tier 분리

## Executive Summary

| 항목 | 내용 |
|------|------|
| **Goal** | 단일 `medications` 테이블을 `catalog_items` + `tracked_medications`로 분리하고, `schedules`를 0..N로 명시화. 한국 인기 영양제 시드 동봉. 등록 플로우를 카탈로그 검색 → 인스턴스 → 알람(skip 가능) 3-step으로 재설계. |
| **Scope** | Drift schema, repository 분리, 등록 플로우, drawer 배지, tracked detail "알람 추가". |
| **Non-goal** | 처방약 카탈로그(KFDA), 네트워크 동기화, 카탈로그 다국어. |
| **Breaking** | Schema breaking. Drift schemaVersion 3 → 4. `onUpgrade`에서 **전체 drop + recreate** (사용자 결정). |

---

## 1. 문제 / Why

### 1.1 현재 동작 (v0.1.0)

```dart
@DriftDatabase(tables: [Medications, Schedules, IntakeLogs, IntervalOccurrences])
class AppDatabase extends _$AppDatabase {
  @override int get schemaVersion => 3;
}
```

- 단일 `medications` 테이블이 카탈로그 속성(`name`, `category`, `dosage`, `unit`, `shape`, `colorHex`, `iconKey`)과 사용자 인스턴스 속성(`memo`, `archived`, `createdAt`)을 함께 보관
- 약 등록 UI(`MedicationAddFlow`)는 **3단계 wizard**: 카테고리 선택 → 이름/시각 → 스케줄
- 사용자는 매번 이름을 직접 타이핑해야 함 — 발견(discover) 단계 부재
- 알람 설정이 등록 플로우에 강제 포함 — "알람 없이 영양제 등록"이 불가능

### 1.2 사용자 가치

- **발견성**: 검색하면 "비타민D3 1000IU" 같은 추천이 나옴 → 마찰 감소
- **자율성**: "오메가3 챙기긴 하는데 알람은 없어도 돼" 같은 시나리오 지원
- **재사용**: 같은 약을 다시 등록할 때 카탈로그에 이미 있음
- **시각 일관성**: 시드 항목은 큐레이션된 아이콘/색상이라 drawer 카드 통일감

---

## 2. 제약

| ID | 제약 | 영향 |
|----|------|------|
| C-1 | **오프라인 원칙** | 카탈로그를 네트워크로 가져올 수 없음 → 번들 JSON |
| C-2 | **앱 사이즈 제한** | 시드 JSON < 30KB (사용자 결정) → 50~100개 |
| C-3 | **사용자 결정: 기존 데이터 wipe** | 마이그레이션 비용 0이지만 명시 안내 필요 |
| C-4 | **schemaVersion 단조 증가** | 3 → 4로 bump. onUpgrade에서 drop+create |
| C-5 | **FK cascade 유지** | tracked 삭제 시 schedules/intake_logs/interval_occurrences 모두 cascade 삭제 |
| C-6 | **id 안정성** | 시드 항목은 앱 업데이트로 갱신될 수 있으므로 안정적 ID 필요 → TEXT slug |
| C-7 | **사용자 추가 catalog_item** | source='user'로 구분, slug는 UUID v4 |
| C-8 | **기존 기능 영향 최소화** | home/calendar/reports 쿼리는 tracked_medications로 redirect만 |

---

## 3. 접근

### 3.1 옵션 비교

| 옵션 | 설명 | 평가 |
|------|------|------|
| **A. 풀 분리 (catalog + tracked + schedules)** | catalog_items(슬러그), tracked_medications(인스턴스), schedules(0..N) | **채택** — Plan에서 확정 |
| B. 동일 테이블 + catalog_id nullable | 기존 medications에 catalog_id 컬럼만 추가 | 검색 UX 모호함, 인스턴스 vs 카탈로그 구분 어려움 |
| C. catalog는 코드로 (Dart enum) | DB 없이 const 리스트 | 사용자 추가 항목 처리 불가, 검색 어려움 |

### 3.2 채택 (A) 데이터 모델

```
catalog_items (TEXT id)
  ↑ N
  │ FK catalog_item_id (nullable)
  │
tracked_medications (INT id)
  ↑ 0..N
  │ FK tracked_medication_id
  ├── schedules
  ├── intake_logs
  └── (intake → schedule_id)

interval_occurrences
  ↑ N
  │ FK schedule_id (변경 없음)
```

핵심 결정:
- `catalog_items.id`: `TEXT` slug (예: `vit-d3-1000iu`, 사용자 추가는 UUID v4). INT autoinc가 아닌 이유: 시드 항목 안정성, 앱 업데이트 시 행 번호 재할당 무관.
- `tracked_medications.catalog_item_id`: **nullable**. 사용자가 "이름만 빠르게 등록" 시 catalog_item 없이도 tracked만 생성 가능 (UX fallback). 단 기본 플로우는 항상 catalog 통해서.
- `schedules.tracked_medication_id`: required FK, cascade delete. 알람 없는 tracked = schedules row 0개.
- `intake_logs.tracked_medication_id`: required FK. `schedule_id`는 nullable로 변경 (스케줄 삭제 후에도 로그 보존 옵션 — 단 본 변경의 scope 아님, 기존대로 required 유지).

---

## 4. Schema 상세

### 4.1 신규 `catalog_items`

```dart
// lib/core/database/tables/catalog_items.dart
import 'package:drift/drift.dart';

/// 카탈로그 source.
/// - seed: 앱 번들 JSON에서 들어온 항목 (read-only)
/// - user: 사용자가 직접 추가한 항목 (편집/삭제 가능)
enum CatalogSource { seed, user }

class CatalogItems extends Table {
  /// 슬러그 또는 UUID. 예: 'vit-d3-1000iu', 'a1b2c3d4-...'
  TextColumn get id => text().withLength(min: 1, max: 64)();

  TextColumn get name => text().withLength(min: 1, max: 80)();
  TextColumn get nameEn => text().withLength(max: 80).nullable()();

  /// 'med' | 'sup' (기존 enum 재사용).
  TextColumn get category => text().withLength(max: 8)();

  /// 기본 용량 표기. 시드 큐레이션 값. tracked에서 override 가능.
  TextColumn get defaultDosage => text().withLength(max: 40).nullable()();
  TextColumn get defaultUnit => text().withLength(max: 20).nullable()();

  TextColumn get shape => text().withLength(max: 20).nullable()();
  TextColumn get colorHex => text().withLength(min: 7, max: 9).nullable()();
  TextColumn get iconKey => text().withLength(max: 40).nullable()();

  /// JSON-encoded `List<String>`. SQLite에 TEXT로 저장, 앱에서 jsonDecode.
  TextColumn get tagsJson => text().nullable()();

  IntColumn get source =>
      intEnum<CatalogSource>().withDefault(Constant(CatalogSource.user.index))();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
```

### 4.2 신규 `tracked_medications` (기존 `medications` 리네이밍 + 정리)

```dart
// lib/core/database/tables/tracked_medications.dart
import 'package:drift/drift.dart';

import 'catalog_items.dart';

class TrackedMedications extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 카탈로그 항목 FK. nullable: 사용자가 카탈로그 없이 직접 등록 가능 (UX fallback).
  /// 권장 경로는 항상 catalog를 통과.
  TextColumn get catalogItemId =>
      text().references(CatalogItems, #id, onDelete: KeyAction.setNull).nullable()();

  /// 카탈로그 기본값 override. null이면 카탈로그 값을 노출.
  TextColumn get customDosage => text().withLength(max: 40).nullable()();
  TextColumn get customUnit => text().withLength(max: 20).nullable()();

  TextColumn get memo => text().nullable()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();

  /// 복용 기간. null이면 무기한.
  DateTimeColumn get startDate => dateTime().nullable()();
  DateTimeColumn get endDate => dateTime().nullable()();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}
```

**중요**: 기존 `medications`에 있던 `name`/`category`/`dosage`/`unit`/`shape`/`colorHex`/`iconKey`는 모두 catalog로 이주. tracked에서 표시할 때는 catalog 조인 + custom override 적용.

### 4.3 `schedules` (FK 컬럼명 변경)

```dart
// lib/core/database/tables/schedules.dart (변경)
class Schedules extends Table {
  IntColumn get id => integer().autoIncrement()();

  // medicationId → trackedMedicationId (rename)
  IntColumn get trackedMedicationId =>
      integer().references(TrackedMedications, #id, onDelete: KeyAction.cascade)();

  // ... 나머지 컬럼 동일 (timeOfDay, repeatKind, daysOfWeekMask, intervalDays,
  //                    remindBeforeMinutes, urgentRepeatMinutes, urgentMaxRepeats,
  //                    startDate, endDate, enabled, createdAt, updatedAt)
}
```

### 4.4 `intake_logs` (FK 컬럼명 변경)

```dart
class IntakeLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get trackedMedicationId =>
      integer().references(TrackedMedications, #id, onDelete: KeyAction.cascade)();
  IntColumn get scheduleId =>
      integer().references(Schedules, #id, onDelete: KeyAction.cascade)();
  // ... 나머지 컬럼 동일
}
```

### 4.5 `interval_occurrences` (변경 없음)

`scheduleId` FK 그대로. schedules cascade로 자동 정리됨.

### 4.6 인덱스

```sql
CREATE INDEX idx_tracked_medications_archived ON tracked_medications(archived);
CREATE INDEX idx_tracked_medications_catalog ON tracked_medications(catalog_item_id);
CREATE INDEX idx_schedules_tracked_med ON schedules(tracked_medication_id, enabled);
CREATE INDEX idx_intake_logs_tracked_med_status ON intake_logs(tracked_medication_id, status, scheduled_at);
CREATE INDEX idx_catalog_items_category ON catalog_items(category);
CREATE INDEX idx_catalog_items_source ON catalog_items(source);
```

검색용 FTS5는 본 PR 스코프 외 (한글 초성 검색은 다음 PR).

---

## 5. Drift 마이그레이션

### 5.1 schemaVersion bump + onUpgrade

```dart
// lib/core/database/app_database.dart
@DriftDatabase(tables: [
  CatalogItems,
  TrackedMedications,
  Schedules,
  IntakeLogs,
  IntervalOccurrences,
])
class AppDatabase extends _$AppDatabase {
  @override int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedCatalogIfEmpty();
        },
        onUpgrade: (m, from, to) async {
          if (from < 4) {
            // 사용자 결정: 전체 wipe + recreate.
            // 기존 medications/schedules/intake_logs/interval_occurrences 모두 삭제.
            for (final table in [
              intakeLogs,
              intervalOccurrences,
              schedules,
              // 기존 medications 테이블 drop (rename이 아니라 wipe 결정)
              // drift는 deleteTable 직접 API 없음 → customStatement 사용
            ]) {
              await m.deleteTable(table.actualTableName);
            }
            await customStatement('DROP TABLE IF EXISTS medications');
            // 신규 테이블 모두 생성
            await m.createAll();
            await _seedCatalogIfEmpty();
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  Future<void> _seedCatalogIfEmpty() async {
    final count = await catalogItems.count().getSingle();
    if (count > 0) return;
    await CatalogSeedLoader(this).loadFromAsset();
  }
}
```

### 5.2 사용자 안내 (앱 측)

Drift 마이그레이션은 silent. 사용자에게 "데이터 초기화됨" 알릴지 결정:
- **옵션 1**: silent (Plan 결정에 따라 wipe 허용). 알림 없음.
- **옵션 2**: 첫 부팅 시 다이얼로그 "v0.2.0 업데이트로 데이터 구조가 바뀌었습니다. 기존 기록은 초기화되었습니다." — 단 알파 사용자만 영향, dogfooding 단계라 옵션 1로 충분.

→ **옵션 1 채택**. v1.0.0 첫 출시 사용자는 0.x 데이터 없음.

---

## 6. 시드 카탈로그

### 6.1 JSON 구조 (`assets/seed/catalog_supplements.ko.json`)

```json
{
  "version": 1,
  "locale": "ko",
  "generatedAt": "2026-05-21",
  "items": [
    {
      "id": "vit-d3-1000iu",
      "name": "비타민 D3",
      "name_en": "Vitamin D3",
      "category": "sup",
      "default_dosage": "1000",
      "default_unit": "IU",
      "shape": "softgel",
      "colorHex": "#FFD580",
      "iconKey": "pill",
      "tags": ["면역", "뼈건강"]
    }
  ]
}
```

### 6.2 카탈로그 큐레이션 가이드 (별도 작업)

`tool/curate_catalog.md` (별도 문서):
- 50~100개 한국 인기 영양제
- 일반 명칭만 (브랜드/제품명 회피 → 저작권 안전)
- 카테고리: 모두 `'sup'` (영양제). 처방약은 후속 PR
- iconKey: 기존 enum `'pill' | 'capsule' | 'tablet' | 'softgel' | 'powder' | 'liquid'` 재사용
- colorHex: 식품 카테고리 컬러 팔레트 (8~10 colors) 한 곳에서 매핑

### 6.3 시드 로더

```dart
// lib/core/database/seed/catalog_seed_loader.dart
class CatalogSeedLoader {
  CatalogSeedLoader(this._db);
  final AppDatabase _db;

  static const _assetPath = 'assets/seed/catalog_supplements.ko.json';

  Future<void> loadFromAsset() async {
    final raw = await rootBundle.loadString(_assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final items = (json['items'] as List).cast<Map<String, dynamic>>();

    await _db.batch((batch) {
      for (final item in items) {
        batch.insert(
          _db.catalogItems,
          CatalogItemsCompanion.insert(
            id: item['id'] as String,
            name: item['name'] as String,
            nameEn: Value(item['name_en'] as String?),
            category: item['category'] as String,
            defaultDosage: Value(item['default_dosage'] as String?),
            defaultUnit: Value(item['default_unit'] as String?),
            shape: Value(item['shape'] as String?),
            colorHex: Value(item['colorHex'] as String?),
            iconKey: Value(item['iconKey'] as String?),
            tagsJson: Value(jsonEncode(item['tags'] ?? [])),
            source: Value(CatalogSource.seed),
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
  }
}
```

### 6.4 시드 갱신 정책

- 시드 JSON 수정 + 앱 업데이트 → `_seedCatalogIfEmpty`는 empty일 때만 INSERT라서 기존 사용자는 신규 시드 안 받음
- 시드 갱신을 위한 후속 옵션 (본 PR 스코프 X):
  - `seed_version` SharedPreferences 키 → 버전 차이 시 `INSERT OR REPLACE` 로 시드만 갱신, source='user' 항목 보호

### 6.5 Validation 스크립트

```dart
// tool/validate_seed_catalog.dart (CI에서 실행)
void main() async {
  final raw = await File('assets/seed/catalog_supplements.ko.json').readAsString();
  final json = jsonDecode(raw) as Map<String, dynamic>;
  final items = (json['items'] as List).cast<Map<String, dynamic>>();

  final ids = <String>{};
  for (final item in items) {
    final id = item['id'] as String;
    if (!RegExp(r'^[a-z0-9][a-z0-9\-]+$').hasMatch(id)) {
      throw 'invalid id slug: $id';
    }
    if (!ids.add(id)) throw 'duplicate id: $id';
    if ((item['category'] as String?) == null) throw '$id missing category';
    if (!{'med', 'sup'}.contains(item['category'])) {
      throw '$id invalid category: ${item['category']}';
    }
    // ... colorHex, iconKey enum check
  }
  print('✓ ${items.length} catalog items validated');
}
```

CI 추가:
```yaml
# .github/workflows/ci.yml — analyze-and-test job에 추가
- name: Validate seed catalog
  run: dart run tool/validate_seed_catalog.dart
```

---

## 7. Repository 분리

### 7.1 `CatalogRepository` (신규)

```dart
// lib/features/catalog/data/catalog_repository.dart
class CatalogRepository {
  CatalogRepository(this._db);
  final AppDatabase _db;

  /// 검색. 이름/영문명/태그에서 부분 일치.
  /// 한글 초성 검색은 다음 PR.
  Stream<List<CatalogItem>> watchSearch(String query) {
    if (query.isEmpty) return watchAll();
    final pattern = '%${query.replaceAll('%', '\\%')}%';
    return (_db.select(_db.catalogItems)
          ..where((c) => c.name.like(pattern) | c.nameEn.like(pattern))
          ..orderBy([
            // seed가 user보다 먼저
            (c) => OrderingTerm(expression: c.source),
            (c) => OrderingTerm(expression: c.name),
          ]))
        .watch();
  }

  Stream<List<CatalogItem>> watchAll() {
    return (_db.select(_db.catalogItems)
          ..orderBy([(c) => OrderingTerm(expression: c.name)]))
        .watch();
  }

  Future<CatalogItem?> getById(String id) =>
      (_db.select(_db.catalogItems)..where((c) => c.id.equals(id)))
          .getSingleOrNull();

  /// 사용자가 카탈로그에 없는 항목 직접 추가 시.
  Future<CatalogItem> addUserCustom({
    required String name,
    required String category,
    String? customId,
  }) async {
    final id = customId ?? const Uuid().v4();
    await _db.into(_db.catalogItems).insert(
          CatalogItemsCompanion.insert(
            id: id,
            name: name,
            category: category,
            source: Value(CatalogSource.user),
          ),
        );
    return (await getById(id))!;
  }

  /// 사용자 추가 항목만 삭제 가능. seed 항목은 ArgumentError.
  Future<void> deleteUserCustom(String id) async {
    final item = await getById(id);
    if (item == null) return;
    if (item.source != CatalogSource.user) {
      throw ArgumentError('cannot delete seed catalog item: $id');
    }
    await (_db.delete(_db.catalogItems)..where((c) => c.id.equals(id))).go();
  }
}
```

### 7.2 `TrackedMedicationRepository` (기존 MedicationRepository 분리)

```dart
class TrackedMedicationRepository {
  TrackedMedicationRepository(this._db, this._notif);
  final AppDatabase _db;
  final MedicationNotificationManager _notif;

  /// drawer 전체 — 알람 있음/없음 모두.
  Stream<List<TrackedMedicationView>> watchAll() {
    // tracked + catalog join + schedules count
    final q = _db.select(_db.trackedMedications).join([
      leftOuterJoin(
        _db.catalogItems,
        _db.catalogItems.id.equalsExp(_db.trackedMedications.catalogItemId),
      ),
      leftOuterJoin(
        _db.schedules,
        _db.schedules.trackedMedicationId.equalsExp(_db.trackedMedications.id) &
            _db.schedules.enabled.equals(true),
      ),
    ])
      ..where(_db.trackedMedications.archived.equals(false));

    return q.watch().map((rows) {
      // group by tracked id, attach catalog + schedules
      ...
    });
  }

  /// 홈 — 알람 활성 스케줄이 1개 이상인 tracked만.
  Stream<List<TrackedMedicationView>> watchActiveScheduled() => watchAll()
      .map((list) => list.where((v) => v.schedules.isNotEmpty).toList());

  Future<int> insertTracked({
    required String? catalogItemId, // null이면 사용자 카탈로그 없이 등록 (fallback)
    String? customDosage,
    String? customUnit,
    String? memo,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return _db.into(_db.trackedMedications).insert(
          TrackedMedicationsCompanion.insert(
            catalogItemId: Value(catalogItemId),
            customDosage: Value(customDosage),
            customUnit: Value(customUnit),
            memo: Value(memo),
            startDate: Value(startDate),
            endDate: Value(endDate),
          ),
        );
  }

  /// 알람 없이 tracked만 등록한 경우, 나중에 알람 추가.
  Future<void> addSchedules(int trackedId, List<ScheduleDraft> schedules) async {
    if (schedules.isEmpty) return;
    await _db.transaction(() async {
      for (final s in schedules) {
        await _db.into(_db.schedules).insert(/* ... */);
      }
    });
    await _notif.syncSchedulesFor(trackedId);
  }

  Future<void> delete(int id) async {
    await _notif.cancelForTracked(id);
    await (_db.delete(_db.trackedMedications)..where((m) => m.id.equals(id))).go();
  }

  // ... setAlarmEnabled, updateTracked, etc.
}
```

### 7.3 View 모델 — `TrackedMedicationView`

```dart
@freezed
class TrackedMedicationView with _$TrackedMedicationView {
  const factory TrackedMedicationView({
    required TrackedMedication tracked,
    required CatalogItem? catalog, // null이면 사용자가 카탈로그 없이 직접 등록
    required List<Schedule> schedules,
  }) = _TrackedMedicationView;

  const TrackedMedicationView._();

  /// 표시 이름: catalog name이 있으면 catalog, 없으면 "이름 없음" (실제로는 fallback 막아야 함).
  String get displayName => catalog?.name ?? '(이름 없음)';

  /// 표시 용량: tracked.custom 우선, 없으면 catalog default.
  String? get displayDosage =>
      tracked.customDosage ?? catalog?.defaultDosage;

  String? get displayUnit =>
      tracked.customUnit ?? catalog?.defaultUnit;

  String? get iconKey => catalog?.iconKey;
  String? get colorHex => catalog?.colorHex;

  bool get hasAlarm => schedules.isNotEmpty;
}
```

### 7.4 기존 `medication_*` 파일 처리

| 기존 파일 | 처리 |
|----------|------|
| `lib/features/medication/data/medication_repository.dart` | **삭제** 후 `tracked_medication_repository.dart`로 분리 |
| `lib/features/medication/data/medication_providers.dart` | rename → `tracked_medication_providers.dart` + catalog_providers 추가 |
| `lib/features/medication/data/intake_repository.dart` | FK 컬럼명만 변경 (medicationId → trackedMedicationId) |
| `lib/features/medication/data/calendar_providers.dart` | tracked로 redirect |
| `lib/features/medication/data/reports_providers.dart` | tracked로 redirect |
| `lib/features/medication/presentation/medication_list_screen.dart` | tracked + catalog join 사용. 카드에 알람 유무 배지 |
| `lib/features/medication/presentation/medication_detail_screen.dart` | catalog 정보 + custom override 노출. "알람 추가" CTA |
| `lib/features/medication/presentation/add/medication_add_flow.dart` | 3-step state machine 재설계 (§8) |

**디렉토리 구조 변화 권장**:
```
lib/features/
├── catalog/                          # 신규
│   ├── data/
│   │   ├── catalog_repository.dart
│   │   └── catalog_providers.dart
│   └── presentation/
│       └── catalog_search_view.dart  # 등록 플로우 Step 1 컴포넌트
└── medication/                       # 기존 폴더 유지, 내부만 tracked로 의미 전환
    ├── data/
    │   ├── tracked_medication_repository.dart
    │   ├── tracked_medication_providers.dart
    │   └── intake_repository.dart
    └── presentation/ (변경)
```

---

## 8. 등록 플로우 재설계 (3-step state machine)

### 8.1 상태

```dart
@freezed
class AddFlowState with _$AddFlowState {
  const factory AddFlowState({
    @Default(1) int step,
    // Step 1 결과
    CatalogItem? selectedCatalog,
    // 또는 step 1에서 "직접 추가" 분기
    @Default(false) bool isCustomEntry,
    String? customName,
    String? customCategory, // 'med' | 'sup'
    // Step 2
    String? customDosage,
    String? customUnit,
    String? memo,
    DateTime? startDate,
    DateTime? endDate,
    // Step 3 (skip 가능)
    @Default([]) List<ScheduleDraft> schedules,
    @Default(false) bool skipAlarm,
    // Submit state
    @Default(false) bool saving,
  }) = _AddFlowState;
}
```

### 8.2 Step 1 — 카탈로그 검색/선택

```
┌─────────────────────────────────────┐
│  < 약/영양제 추가         (1/3)     │
├─────────────────────────────────────┤
│  🔍 [비타민D                      ] │
├─────────────────────────────────────┤
│  ┌───┐ 비타민 D3       1000IU      │
│  │💊│ 면역, 뼈건강      seed       │
│  └───┘                              │
│  ┌───┐ 비타민 D2          400IU    │
│  │💊│                     seed     │
│  └───┘                              │
│  ┌───┐ 종합비타민                  │
│  │💊│                     seed     │
│  └───┘                              │
│                                     │
│  ─── 결과가 없나요? ───             │
│  [+ 직접 추가하기]                 │
└─────────────────────────────────────┘
```

- 검색 결과 탭 → `selectedCatalog` 설정 → 다음 단계로
- "직접 추가" 탭 → `isCustomEntry = true` → Step 2에서 이름/카테고리 입력

### 8.3 Step 2 — 인스턴스 속성

```
┌─────────────────────────────────────┐
│  < 비타민 D3 추가           (2/3)   │
├─────────────────────────────────────┤
│  카테고리:   영양제                 │
│  용량:      [1000     ] [IU      ] │
│                       (기본값)      │
│  메모:      [..............      ] │
│  복용 기간:  [시작 ▾] ~ [종료 ▾]    │
├─────────────────────────────────────┤
│       [이전]    [다음]              │
└─────────────────────────────────────┘
```

- catalog 선택했으면 prefill (defaultDosage/defaultUnit), 사용자가 override 가능
- "직접 추가" 분기였으면 카테고리 토글 + 이름 입력 필드 추가

### 8.4 Step 3 — 알람 (skip 가능)

```
┌─────────────────────────────────────┐
│  < 비타민 D3 알람          (3/3)    │
├─────────────────────────────────────┤
│  복용 시각:                         │
│  ┌─────┐                            │
│  │08:00│  + 시각 추가               │
│  └─────┘                            │
│                                     │
│  반복:    ○ 매일                    │
│           ○ 특정 요일               │
│           ○ N일마다                 │
│                                     │
│  사전 알림: [없음     ▾]            │
├─────────────────────────────────────┤
│  [건너뛰기]   [완료]                │
└─────────────────────────────────────┘
```

- **"건너뛰기"** 버튼 = `skipAlarm = true` → schedules 0개로 tracked만 저장
- **"완료"** = 입력한 schedules로 tracked + schedules 동시 저장

### 8.5 저장 트랜잭션

```dart
Future<int> _save(AddFlowState s, Ref ref) async {
  final catalogRepo = ref.read(catalogRepositoryProvider);
  final trackedRepo = ref.read(trackedMedicationRepositoryProvider);

  // 1) catalog 결정
  String? catalogId;
  if (s.isCustomEntry) {
    final item = await catalogRepo.addUserCustom(
      name: s.customName!,
      category: s.customCategory!,
    );
    catalogId = item.id;
  } else {
    catalogId = s.selectedCatalog!.id;
  }

  // 2) tracked 인스턴스 insert
  final trackedId = await trackedRepo.insertTracked(
    catalogItemId: catalogId,
    customDosage: s.customDosage,
    customUnit: s.customUnit,
    memo: s.memo,
    startDate: s.startDate,
    endDate: s.endDate,
  );

  // 3) schedules (skip 안 했을 때만)
  if (!s.skipAlarm && s.schedules.isNotEmpty) {
    await trackedRepo.addSchedules(trackedId, s.schedules);
  }

  return trackedId;
}
```

### 8.6 Tracked Detail — "알람 추가"

알람이 0개인 tracked에 대해 detail 화면 상단에 prominent CTA:

```
┌─────────────────────────────────────┐
│  < 비타민 D3                ⋮       │
├─────────────────────────────────────┤
│  ┌───┐ 비타민 D3                   │
│  │💊│ 1000IU · 영양제              │
│  └───┘                              │
│                                     │
│  ⚠️ 알람이 설정되지 않았어요         │
│  복용 시간을 등록하면 잊지 않게      │
│  도와드릴게요.                      │
│       [알람 추가]                  │
├─────────────────────────────────────┤
│  ...                                │
└─────────────────────────────────────┘
```

"알람 추가" 탭 → 기존 Step 3 sheet 재사용 (state는 tracked 컨텍스트로 초기화).

---

## 9. UI 변경 — Drawer

### 9.1 카드에 알람 유무 배지

```dart
// medication_list_screen.dart 내 카드 빌더
Widget _buildCard(TrackedMedicationView v) {
  return Card(
    child: ListTile(
      leading: _iconForCatalog(v.catalog),
      title: Text(v.displayName),
      subtitle: Text('${v.displayDosage ?? ''} ${v.displayUnit ?? ''}'),
      trailing: v.hasAlarm
          ? Icon(Icons.alarm_on, color: AppColors.primary)
          : Icon(Icons.alarm_off, color: AppColors.muted),
    ),
  );
}
```

기존 정렬/검색 (`feat/drawer-sort`, `feat/drawer-search`) 로직과 호환:
- 검색: tracked.displayName 또는 catalog.name으로 매칭
- 정렬: 이름순/등록순/다음 복용순. "다음 복용순"은 hasAlarm=false인 항목을 맨 뒤로

### 9.2 검색

drawer 검색은 **카탈로그 통합 검색이 아닌, 본인의 tracked 목록 안에서만 검색** (기존 동작 유지). 카탈로그 검색은 등록 플로우 Step 1에서만.

이유: drawer는 "내가 챙기는 약" 뷰. 거기서 카탈로그 전체 보여주면 혼동.

---

## 10. 라우팅 변경

기존:
- `/drawer/new` → `MedicationAddFlow()` 3-step
- `/drawer/:id` → `MedicationDetailScreen(medicationId: id)`
- `/drawer/:id/edit` → `MedicationAddFlow(medicationId: id)`

변경:
- 경로 그대로 유지 (UX 안정성)
- 파라미터명 의미만 `trackedMedicationId`로 의식적으로 사용
- `medicationId` 변수명은 `trackedMedicationId`로 점진 rename (한 PR에 다 못 들어가면 후속)

deep link payload (notification → tracked detail)도 동일 경로 사용. `notification_action_handler.dart` 내 `medicationId` 변수명만 정리.

---

## 11. 영향 받는 코드 파일

| 파일 | 변경 종류 | Effort |
|------|----------|:------:|
| `lib/core/database/tables/medications.dart` | 삭제 | S |
| `lib/core/database/tables/catalog_items.dart` | 신규 | M |
| `lib/core/database/tables/tracked_medications.dart` | 신규 | M |
| `lib/core/database/tables/schedules.dart` | FK 컬럼명 변경 | S |
| `lib/core/database/tables/intake_logs.dart` | FK 컬럼명 변경 | S |
| `lib/core/database/app_database.dart` | schemaVersion 4, onUpgrade, _seedCatalogIfEmpty | M |
| `lib/core/database/seed/catalog_seed_loader.dart` | 신규 | M |
| `assets/seed/catalog_supplements.ko.json` | 신규 (50~100 큐레이션) | L |
| `tool/validate_seed_catalog.dart` | 신규 | S |
| `lib/features/catalog/data/catalog_repository.dart` | 신규 | M |
| `lib/features/catalog/data/catalog_providers.dart` | 신규 | S |
| `lib/features/catalog/presentation/catalog_search_view.dart` | 신규 (Step 1 컴포넌트) | M |
| `lib/features/medication/data/medication_repository.dart` | 삭제 → tracked로 분리 | M |
| `lib/features/medication/data/tracked_medication_repository.dart` | 신규 | L |
| `lib/features/medication/data/tracked_medication_providers.dart` | 신규 (기존 medication_providers rename) | S |
| `lib/features/medication/data/intake_repository.dart` | FK 변경 | S |
| `lib/features/medication/data/calendar_providers.dart` | FK 변경 | S |
| `lib/features/medication/data/reports_providers.dart` | FK 변경 | S |
| `lib/features/medication/presentation/medication_list_screen.dart` | 알람 유무 배지, view model 적용 | M |
| `lib/features/medication/presentation/medication_detail_screen.dart` | catalog 표시, "알람 추가" CTA | M |
| `lib/features/medication/presentation/add/medication_add_flow.dart` | 3-step state machine 재설계 | L |
| `lib/features/medication/presentation/add/steps/step1_catalog.dart` | 신규 (기존 step1_category 대체) | M |
| `lib/features/medication/presentation/add/steps/step2_instance.dart` | 기존 step2_name 대체 | M |
| `lib/features/medication/presentation/add/steps/step3_schedule.dart` | "건너뛰기" 버튼 추가 | S |
| `lib/features/home/presentation/home_screen.dart` | tracked + 알람있음 필터 적용 | S |
| `lib/core/notifications/medication_notification_manager.dart` | cancelForTracked, syncSchedulesFor 이름 정리 (인자 의미 변경) | M |
| `lib/core/notifications/notification_action_handler.dart` | medicationId → trackedMedicationId 의미 정리 | S |
| `pubspec.yaml` | `uuid: ^4.x` 추가, assets에 `assets/seed/` 등록 | S |
| `.github/workflows/ci.yml` | validate_seed_catalog 단계 추가 | S |

Effort 합: **S 10개 + M 12개 + L 4개**. 1 PR로는 큼 → 4 phase로 분할 (§14).

---

## 12. 테스트 전략

### 12.1 단위 테스트 (drift in-memory)

- `CatalogRepository`: 시드 로드, search, addUserCustom, deleteUserCustom (seed 보호)
- `TrackedMedicationRepository`: insertTracked (catalog/null 둘 다), addSchedules, view join 정확성
- 마이그레이션: 빈 DB → schemaVersion 4 부팅 → 시드 100개 INSERT 확인

### 12.2 골든 테스트

- drawer 카드 (알람있음 / 알람없음)
- Step 1 카탈로그 검색 결과
- Step 3 "건너뛰기" 버튼

### 12.3 통합 테스트 (선택)

Patrol E2E: "카탈로그 검색 → 선택 → 인스턴스 정보 → 건너뛰기 → drawer에 알람없음 카드 표시 → tracked detail에서 알람 추가" 풀 시나리오. 본 PR 스코프 외.

### 12.4 기존 widget_test 살리기

`test: drift mock harness` 별도 PR에서 in-memory drift 인프라 정비. 그 PR이 본 변경 후에 가야 catalog/tracked harness까지 한 번에 정리됨.

---

## 13. Open Decisions (Design 단계 결정 완료 / 후속 결정)

| 결정 | Design 결론 | 상태 |
|------|------------|------|
| 카탈로그 id 타입 | TEXT slug | ✅ |
| 시드 vs 사용자 항목 구분 | `source` enum (seed/user) | ✅ |
| 사용자 추가 카탈로그 삭제 시 | `setNull` cascade (tracked는 남고 catalog만 사라짐). source='seed' 삭제 금지 | ✅ |
| tracked.catalog_item_id nullable | true (UX fallback) | ✅ |
| schedules 0개 = 알람 없는 tracked | 허용 | ✅ |
| 마이그레이션 | 전체 drop+create | ✅ |
| 시드 갱신 (앱 업데이트 후 기존 사용자) | 본 PR 스코프 X. 후속 PR에서 seed_version 기반 갱신 | 후속 |
| 카탈로그 항목 사용자 평점 | Out of scope | ✅ |
| 같은 catalog_item을 여러 tracked로 등록 | 허용 (DB 제약 없음, UX 구분만 필요 시 후속) | ✅ |
| 카테고리 enum 확장 | 'med'/'sup'만 유지, 'herb' 등은 후속 | ✅ |
| 다국어 카탈로그 | en은 nameEn 컬럼만, ko 우선 | ✅ |
| FTS5 한글 초성 검색 | 후속 PR | 후속 |

---

## 14. 구현 phase 분할 (PR 시퀀스)

스코프 큰 변경이라 단일 PR보다 4 phase로 분할 권장:

### Phase 1 — Schema + 시드 인프라 (PR 1)
- catalog_items / tracked_medications 테이블, schedules / intake_logs FK 변경
- schemaVersion 4 + onUpgrade drop+create
- catalog_seed_loader + 최소 시드 (50개)
- validate_seed_catalog tool + CI 통합
- 기존 repository 임시 호환 wrapper (lib 컴파일만 통과)
- **본 PR이 lib 컴파일 깨뜨려도 됨 — Phase 2가 따라옴 직후**

### Phase 2 — Repository 분리 + 기존 화면 redirect (PR 2)
- CatalogRepository + TrackedMedicationRepository
- 기존 medication_* providers → tracked_*로 redirect
- 기존 화면(home/drawer/detail/calendar/reports)을 tracked view model로 동작
- 등록 플로우는 기존 그대로 유지 (catalog 없이 tracked만 생성)

### Phase 3 — 등록 플로우 3-step 재설계 (PR 3)
- Step 1 catalog search view + Step 2 instance + Step 3 alarm skip
- drawer 카드에 알람 유무 배지
- tracked detail "알람 추가" CTA

### Phase 4 — 시드 큐레이션 확장 + 한글 초성 검색 (PR 4)
- 시드 100개로 확장
- FTS5 + 초성 색인

각 phase는 독립적으로 머지 가능 + 사용자에게 incremental 가치 전달.

---

## 15. Risks (Design 단계)

| Risk | Mitigation |
|------|-----------|
| Phase 1 머지 후 Phase 2 지연 시 lib 컴파일 깨짐 | Phase 1에 임시 호환 wrapper. Phase 2를 즉시 follow-up. 또는 두 phase를 한 PR로 묶기 |
| 사용자가 wipe 안내 없어 데이터 사라졌다고 컴플레인 | dogfooding 단계라 위험 낮음. release notes에 "v0.2.0: 데이터 구조 변경, 기존 기록 초기화" 명시 |
| catalog seed JSON 큐레이션 시간 미확보 | Phase 1에서는 50개로 시작 (모태 plan의 In Scope 최소치). Phase 4에서 확장 |
| Step 3 "건너뛰기" 사용자 의도 혼동 | "지금 설정 / 나중에 설정" 같은 양자택일 wording. tracked detail의 "알람 추가" CTA로 후속 진입 명확 |
| catalog_item_id setNull → catalog 사라져도 tracked만 남음 → 표시할 이름 없음 | view model에서 `displayName = catalog?.name ?? '(이름 없음)'`. UX는 별도 안내 (Phase 3에서) |
| 시드 100개 INSERT 콜드스타트 지연 | batch insert 측정. 200ms 초과 시 background isolate로 분리 |

---

## 16. Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2026-05-21 | Initial design. Plan v1.0 기반 schema/UI/마이그레이션/PR 분할 4 phase 확정 | gamja (assisted) |
