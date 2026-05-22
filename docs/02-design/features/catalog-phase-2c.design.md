---
template: design
version: 1.2
feature: catalog-phase-2c
date: 2026-05-21
author: 정성훈 <shjung@surromind.ai>
project: pill_mate
version_app: 1.0.0+4
---

# catalog-phase-2c Design Document

> **Summary**: `tracked_medications`의 카탈로그 중복 메타 컬럼을 schemaVersion 7로 drop하고, catalog 우선 + `customDosage/customUnit` override 모델로 정리. 마이그레이션 SQL · 백필 알고리즘 · caller 체크리스트를 명세.
>
> **Project**: pill_mate
> **Version**: 1.0.0+4
> **Author**: 정성훈
> **Date**: 2026-05-21
> **Status**: Draft
> **Planning Doc**: [catalog-phase-2c.plan.md](../../01-plan/features/catalog-phase-2c.plan.md)

### Pipeline References

| Phase | Document | Status |
|-------|----------|--------|
| Phase 1 (Schema) | (inline below §3) | ✅ |
| Phase 2 (Convention) | Drift+Riverpod 기존 패턴 준용 | ✅ |
| Phase 3 (Mockup) | UI 변경 없음 | N/A |
| Phase 4 (API) | 외부 API 없음 (local Drift) | N/A |

---

## 1. Overview

### 1.1 Design Goals

- **데이터 정합성**: `catalog_items`를 메타 정보의 단일 진실 공급원(SSOT)로 확정. tracked는 인스턴스 상태 + override만 보유.
- **무손실 마이그레이션**: 기존 사용자 데이터(tracked / schedules / intake_logs / interval_occurrences) 전건 보존하면서 컬럼 drop + 백필.
- **컴파일 타임 검출**: 컬럼 제거를 통해 누락된 caller 마이그레이션은 Drift 코드 재생성 + `flutter analyze`에서 강제 노출.
- **점진 rename**: Phase 2A의 `medicationId` 호환 변수는 FK 의미가 명확한 곳부터 `trackedMedicationId`로 전환. 알림 payload 토큰은 호환성 유지.

### 1.2 Design Principles

- **SSOT 분리**: catalog = 정의(공유), tracked = 인스턴스(개인). override는 nullable만.
- **마이그레이션 정합 우선**: 실패 시 신규 테이블만 drop하면 rollback 가능한 “new table + swap” 패턴 (v6 선례 재활용).
- **타입 시스템 우선**: 컬럼/필드 제거로 caller 누락은 컴파일 에러로 잡힘 → 검토 누락 위험 최소화.
- **UI 무변경**: 디자인/UX 변경 없음 — Phase 3에서 확정된 UI를 그대로 유지하면서 데이터 모델만 정리.

---

## 2. Architecture

### 2.1 Component Diagram

```
┌──────────────────────────────────────────────────────────────┐
│                         Presentation                          │
│   home_screen · calendar_screen · reports_screen ·           │
│   medication_list · medication_detail · sheets · mockups     │
└─────────────────────────┬────────────────────────────────────┘
                          │  display* getters (catalog 우선 → override 폴백)
                          ▼
┌──────────────────────────────────────────────────────────────┐
│                          Application                          │
│   TrackedMedicationWithSchedules (view model)                │
│   TrackedMedicationRepository (insert/update with catalog)   │
└─────────────────────────┬────────────────────────────────────┘
                          │
                          ▼
┌──────────────────────────────────────────────────────────────┐
│                         Domain / Data                         │
│   ┌──────────────┐     ┌───────────────────┐                 │
│   │ catalog_items│ ◀── │tracked_medications│                 │
│   │  (SSOT)      │     │  (override only)  │                 │
│   └──────────────┘     └───────┬───────────┘                 │
│                                ▼                              │
│                         ┌──────────────┐    ┌──────────────┐ │
│                         │  schedules   │ ── │ intake_logs  │ │
│                         └──────────────┘    └──────────────┘ │
└──────────────────────────────────────────────────────────────┘
```

### 2.2 Data Flow

```
[등록] step1 catalog 선택 → step2 인스턴스 속성(override) → step3 알람
  → repository.insertWithSchedules(catalogId, customDosage?, customUnit?, memo?, schedules[])
  → catalog 존재 확인(_resolveOrCreateCatalog) → tracked insert (catalogItemId FK)
  → schedules insert

[조회] watchAll() → tracked LEFT JOIN catalog
  → TrackedMedicationWithSchedules { medication, catalog, schedules }
  → caller가 display* getter로 표시값 획득

[마이그레이션 v6→v7]
  PRAGMA foreign_keys = OFF
  → 신규 tracked_medications_new 생성 (메타 컬럼 없음, override + memo만)
  → 백필 INSERT: 기존 tracked → catalog 보장 → tracked_new INSERT
  → 기존 tracked DROP, RENAME tracked_new → tracked_medications
  PRAGMA foreign_keys = ON
```

### 2.3 Dependencies

| Component | Depends On | Purpose |
|-----------|-----------|---------|
| `app_database.dart` | `catalog_seed_loader`, `tables/*` | schemaVersion 6→7 onUpgrade |
| `TrackedMedicationRepository` | `AppDatabase`, `MedicationNotificationManager`, `_resolveOrCreateCatalog` | 새 Draft 시그니처 처리 |
| `TrackedMedicationWithSchedules` | `CatalogItem`, `TrackedMedication`, `Schedule` | display getter 제공 |
| Caller layer (14파일) | `TrackedMedicationWithSchedules.display*` | 메타 접근 단일 경로 |
| `medication_notification_manager` | `TrackedMedicationWithSchedules` (catalog 포함) | 알림 본문에 약 이름 사용 |

---

## 3. Data Model

### 3.1 Entity Definition (After Migration)

**`catalog_items`** (변경 없음 — SSOT)
```dart
class CatalogItems extends Table {
  TextColumn get id => text().withLength(min: 1, max: 64)();    // slug or UUID
  TextColumn get name => text().withLength(min: 1, max: 80)();
  TextColumn get nameEn => text().nullable()();
  TextColumn get category => text().withLength(max: 8)();        // 'med' | 'sup'
  TextColumn get defaultDosage => text().nullable()();
  TextColumn get defaultUnit => text().nullable()();
  TextColumn get shape => text().nullable()();
  TextColumn get colorHex => text().nullable()();
  TextColumn get iconKey => text().nullable()();
  TextColumn get tagsJson => text().nullable()();
  IntColumn get source => intEnum<CatalogSource>()();            // seed | user
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
```

**`tracked_medications`** (After v7)
```dart
class TrackedMedications extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// catalog FK. nullable: 카탈로그가 setNull로 끊긴 legacy 케이스 보호.
  /// 신규 등록은 항상 catalog 보장(repository 트랜잭션에서 _resolveOrCreateCatalog).
  TextColumn get catalogItemId =>
      text().references(CatalogItems, #id, onDelete: KeyAction.setNull).nullable()();

  /// catalog.defaultDosage override 전용. null이면 catalog 값 사용.
  TextColumn get customDosage => text().withLength(max: 40).nullable()();

  /// catalog.defaultUnit override 전용. null이면 catalog 값 사용.
  TextColumn get customUnit => text().withLength(max: 20).nullable()();

  /// 사용자 인스턴스 상태.
  TextColumn get memo => text().nullable()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
```

**제거되는 컬럼:** `name`, `category`, `shape`, `colorHex`, `iconKey`.
**rename:** `dosage` → `customDosage`, `unit` → `customUnit` (의미 명확화).
**유지:** `id`, `catalogItemId`, `memo`, `archived`, `createdAt`, `updatedAt`.

**`schedules`, `intake_logs`, `interval_occurrences`**: 변경 없음. FK 컬럼명도 `medicationId` 유지 (Phase 2A 호환 결정 준수).

### 3.2 Entity Relationships

```
catalog_items (id TEXT, SSOT)
   │ 1
   │ 0..N (setNull on delete)
   ▼
tracked_medications (id INT, override + memo + archived)
   │ 1
   │ 0..N (cascade)
   ▼
schedules (id INT, timeOfDay + repeatKind)
   │ 1
   │ 0..N (setNull on delete; v6에서 intake_logs도 setNull)
   ▼
intake_logs (id INT, scheduledAt + status + medNameSnapshot)

schedules ──── 1..N ──── interval_occurrences (cascade)
```

### 3.3 Database Schema — Migration SQL (v6 → v7)

> v5 → v6 intake_logs 마이그레이션(`app_database.dart:60-95`)과 동일 패턴.
> trigger: `from < 7` (v6에서 v7로 올라올 때만 실행 — v7 신규 설치는 `onCreate.createAll()`만 호출).

```dart
if (from < 7) {
  await customStatement('PRAGMA foreign_keys = OFF');

  // 1) 백필 누락 방지: tracked 메타를 끌어올릴 catalog가 없으면 user-source 생성.
  //    같은 (name, category) catalog가 이미 있으면 재사용 (dedupe).
  //    seed catalog는 절대 수정/생성 X.
  await customStatement('''
    INSERT INTO catalog_items
      (id, name, category, default_dosage, default_unit, shape, color_hex,
       icon_key, tags_json, source, created_at)
    SELECT
      lower(hex(randomblob(16))),               -- pseudo-UUID
      t.name,
      COALESCE(t.category, 'sup'),
      t.dosage,
      t.unit,
      t.shape,
      t.color_hex,
      t.icon_key,
      NULL,
      1,                                         -- CatalogSource.user.index
      strftime('%s','now')
    FROM tracked_medications t
    WHERE t.catalog_item_id IS NULL
      AND NOT EXISTS (
        SELECT 1 FROM catalog_items c
        WHERE c.name = t.name
          AND c.category = COALESCE(t.category, 'sup')
      )
  ''');

  // 2) catalog_item_id가 NULL인 tracked에 catalog 연결 (방금 만들거나 기존 매칭).
  await customStatement('''
    UPDATE tracked_medications
       SET catalog_item_id = (
             SELECT c.id FROM catalog_items c
              WHERE c.name = tracked_medications.name
                AND c.category = COALESCE(tracked_medications.category, 'sup')
              ORDER BY (c.source = 0) DESC,        -- seed 우선
                       c.created_at ASC
              LIMIT 1
           )
     WHERE catalog_item_id IS NULL
  ''');

  // 3) 새 tracked_medications_new — 메타 컬럼 제거 + dosage/unit rename.
  await customStatement('''
    CREATE TABLE tracked_medications_new (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      catalog_item_id TEXT NULL
        REFERENCES catalog_items(id) ON DELETE SET NULL,
      custom_dosage TEXT NULL,
      custom_unit TEXT NULL,
      memo TEXT NULL,
      archived INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL DEFAULT (strftime('%s','now')),
      updated_at INTEGER NOT NULL DEFAULT (strftime('%s','now'))
    )
  ''');

  // 4) 데이터 복사 — override 컬럼은 catalog 기본값과 다를 때만 보관.
  //    같으면 NULL로 두어 향후 catalog 갱신이 자동 반영되도록.
  await customStatement('''
    INSERT INTO tracked_medications_new
      (id, catalog_item_id, custom_dosage, custom_unit, memo, archived,
       created_at, updated_at)
    SELECT
      t.id,
      t.catalog_item_id,
      CASE
        WHEN t.dosage IS NOT NULL
         AND t.dosage != COALESCE(c.default_dosage, '')
        THEN t.dosage
        ELSE NULL
      END,
      CASE
        WHEN t.unit IS NOT NULL
         AND t.unit != COALESCE(c.default_unit, '')
        THEN t.unit
        ELSE NULL
      END,
      t.memo,
      t.archived,
      t.created_at,
      t.updated_at
    FROM tracked_medications t
    LEFT JOIN catalog_items c ON c.id = t.catalog_item_id
  ''');

  // 5) FK 무결성 보호 — schedules/intake_logs/interval_occurrences는 그대로.
  //    SQLite는 ALTER TABLE로 FK 변경 불가하므로, swap이지만 FK는 동일 컬럼명/타입이라
  //    foreign_keys OFF 상태에서 swap 가능.
  await customStatement('DROP TABLE tracked_medications');
  await customStatement(
      'ALTER TABLE tracked_medications_new RENAME TO tracked_medications');

  // 6) 인덱스 재생성 (catalog FK 조회 빈도 높음).
  await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_tracked_meds_archived '
      'ON tracked_medications(archived)');
  await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_tracked_meds_catalog '
      'ON tracked_medications(catalog_item_id)');

  await customStatement('PRAGMA foreign_keys = ON');
  return;
}
```

**SQL 검증 포인트:**
- (1)의 INSERT는 `WHERE NOT EXISTS` 가드로 (name, category) 중복 catalog 생성 방지.
- (1)의 `lower(hex(randomblob(16)))`는 32자 hex — UUID 슬러그 형태로 충분. 정식 UUID v4가 필요하면 앱 측에서 fix-up하지만 본 마이그레이션에선 SQLite native로 충분.
- (2)의 `ORDER BY (source = 0) DESC, created_at ASC`는 seed > user 우선 + 가장 오래된 것 우선.
- (4)의 `CASE`는 “catalog 기본값과 같으면 override NULL로 비움” — 향후 catalog 큐레이션 갱신이 자동 반영되는 효과.

### 3.4 Backfill 알고리즘 (의사코드)

```
function migrateTrackedTov7():
  ── Phase A: catalog 보장 ──
  for each tracked t WHERE t.catalog_item_id IS NULL:
    name = t.name
    category = t.category ?? 'sup'

    existing = catalog WHERE name = name AND category = category
    if existing:
      continue  # 매칭 catalog 있음, (2)에서 link
    else:
      create user-source catalog {
        id: uuid_v4(),
        name, category,
        default_dosage: t.dosage,
        default_unit: t.unit,
        shape: t.shape,
        color_hex: t.color_hex,
        icon_key: t.icon_key,
        tags_json: NULL,
        source: 'user',
      }

  ── Phase B: tracked → catalog link ──
  for each tracked t WHERE t.catalog_item_id IS NULL:
    matched = catalog WHERE name=t.name AND category=COALESCE(t.category,'sup')
             ORDER BY (source='seed') DESC, created_at ASC
             LIMIT 1
    t.catalog_item_id = matched.id

  ── Phase C: 신규 테이블에 override만 복사 ──
  for each tracked t:
    c = catalog[t.catalog_item_id]
    custom_dosage = (t.dosage != c.default_dosage) ? t.dosage : NULL
    custom_unit   = (t.unit   != c.default_unit)   ? t.unit   : NULL
    insert tracked_medications_new (
      id, catalog_item_id, custom_dosage, custom_unit, memo, archived,
      created_at, updated_at
    )

  ── Phase D: swap ──
  drop tracked_medications
  rename tracked_medications_new -> tracked_medications
```

**Edge cases:**
- `t.catalog_item_id`가 이미 set이지만 catalog가 사라진 경우(setNull 이전 시점 데이터 잔여): Phase A는 skip, Phase B도 skip(이미 set). Phase C에서 LEFT JOIN catalog가 NULL → custom_dosage/unit은 t.dosage/unit 그대로 보존. **데이터 유실 없음**.
- `t.name`이 빈 문자열 (legacy): 이론상 NOT NULL이지만 빈 문자열 가능. Phase A에서 빈 이름 catalog 생성 가능성 → 후속 cleanup job에서 정리. 본 마이그레이션 스코프 외.
- catalog 충돌 (같은 name + category가 seed에도 user에도 있는 경우): seed 우선 link (ORDER BY source=0 DESC).
- `medNameSnapshot`(intake_logs)은 영향 없음 — tracked.name이 사라져도 이미 스냅샷이 있으면 표시 가능.

---

## 4. API Specification

본 작업은 외부 API 없음. Repository 메서드 시그니처 변경만 명세.

### 4.1 Repository Interface (After)

```dart
class TrackedMedicationDraft {
  const TrackedMedicationDraft({
    required this.catalogItemId,   // 신규: 필수
    required this.times,
    required this.repeatKind,
    this.customDosage,             // rename: dosage → customDosage
    this.customUnit,               // rename: unit → customUnit
    this.daysOfWeekMask,
    this.intervalDays,
    this.memo,
    this.remindBeforeMinutes,
  });

  final String catalogItemId;       // 필수: 사전 resolve된 catalog id
  final String? customDosage;
  final String? customUnit;
  final String? memo;
  final List<String> times;
  final RepeatKind repeatKind;
  final int? daysOfWeekMask;
  final int? intervalDays;
  final int? remindBeforeMinutes;
}

class TrackedMedicationRepository {
  // 시그니처 변경: name/category/shape/colorHex/iconKey 받지 않음.
  // catalog는 호출자가 사전에 _resolveOrCreateCatalog로 확보해 catalogItemId 전달.
  Future<int> insertWithSchedules(TrackedMedicationDraft draft);
  Future<void> updateWithSchedules(int id, TrackedMedicationDraft draft);
}
```

### 4.2 Draft 입력 경로 (등록 플로우)

```
step1_category   → category 선택 ('med' | 'sup')
step2_name       → catalog 검색/선택 또는 신규 catalog 생성 (user-source)
                   → catalogItemId 확정
                   → customDosage/customUnit (catalog 기본값과 다르면)
step3_schedule   → times + repeatKind + daysOfWeekMask/intervalDays
final            → TrackedMedicationDraft 생성 → repo.insertWithSchedules(draft)
```

### 4.3 display* Getter (변경 없음, caller 사용처만 확대)

```dart
extension on TrackedMedicationWithSchedules {
  String get displayName       => catalog?.name        ?? '(이름 없음)';
  String? get displayCategory  => catalog?.category;
  String? get displayDosage    => medication.customDosage ?? catalog?.defaultDosage;
  String? get displayUnit      => medication.customUnit   ?? catalog?.defaultUnit;
  String? get displayShape     => catalog?.shape;
  String? get displayColorHex  => catalog?.colorHex;
  String? get displayIconKey   => catalog?.iconKey;
}
```

> 변경점: `displayName/Category/Shape/ColorHex/IconKey`의 폴백이 더 이상 `medication.*`이 아님 — 컬럼 자체가 없어졌기 때문. catalog NULL이면 fallback 텍스트로 처리.

---

## 5. UI/UX Design

UI 변경 없음. 모든 화면이 `display*` getter를 통해 동일한 표시값을 받음.

### 5.1 Caller 마이그레이션 매핑

| Caller 패턴 (Before) | After |
|----------------------|-------|
| `m.medication.name` | `m.displayName` |
| `m.medication.category` | `m.displayCategory` |
| `m.medication.dosage` | `m.displayDosage` |
| `m.medication.unit` | `m.displayUnit` |
| `m.medication.shape` | `m.displayShape` |
| `m.medication.colorHex` | `m.displayColorHex` |
| `m.medication.iconKey` | `m.displayIconKey` |
| `m.medication.memo` | `m.medication.memo` (유지) |
| `m.medication.archived` | `m.medication.archived` (유지) |
| `m.medication.id` | `m.medication.id` (유지) |
| `m.medication.createdAt` | `m.medication.createdAt` (유지) |

> `medication.id/memo/archived/createdAt/updatedAt`는 tracked 본질 컬럼이므로 그대로.

---

## 6. Error Handling

### 6.1 Migration Error Codes

| 시나리오 | 처리 |
|----------|------|
| catalog INSERT 충돌(랜덤 UUID 중복) | SQLite hex randomblob 충돌 확률 0에 수렴, 무시 |
| 백필 후 tracked.catalog_item_id가 여전히 NULL | Phase A 실패 → 사용자 데이터 보존 위해 마이그레이션 중단 + 에러 로그. 신규 테이블 swap 안 함 (rollback 자동). |
| swap 후 schedules/intake_logs FK 깨짐 | tracked.id 유지(주기 신규 row만 추가)로 영향 없음. PRAGMA foreign_keys=OFF 동안만 inconsistency 허용 후 ON에서 검증. |
| `flutter analyze` 실패 (caller 누락) | 빌드 실패 → 머지 차단. DoD. |

### 6.2 Runtime Error Handling

- `displayName == null` (catalog가 setNull로 끊긴 legacy): UI에서 `'(이름 없음)'` 폴백 + 사용자에게 “약 정보 복원” CTA 노출(별도 PR — 본 PR은 폴백 텍스트만).

---

## 7. Security Considerations

- [x] DB-only 변경, 외부 API/입력 없음 — 인증/XSS/SQLi 영향 없음
- [x] SQLite 마이그레이션 SQL은 인자 없음(`?` placeholder 미사용) — injection 위험 없음
- [x] 사용자 데이터 wipe 없음 — 알파(v4→v5) 정책과 다름
- [x] FK 무결성 — PRAGMA foreign_keys ON으로 마이그레이션 후 재검증

---

## 8. Test Plan

### 8.1 Test Scope

| Type | Target | Tool |
|------|--------|------|
| Migration Test | v6 DB → v7 onUpgrade | Drift `IntegrationTest` + 수동 |
| Repository Test | `insertWithSchedules` 새 시그니처 | flutter test (기존 패턴) |
| Build Test | flutter analyze --fatal-warnings | CI |
| UI Smoke Test | 홈/캘린더/리포트/드로어/상세 회귀 | 실기기 manual |

### 8.2 Test Cases

**Migration:**
- [ ] v6 DB (시드 + user-source catalog + tracked 5건) → v7 upgrade → row count 동일 확인
- [ ] tracked 중 `catalog_item_id IS NULL` 1건 → 백필 후 catalog 생성 + link 확인
- [ ] tracked.dosage == catalog.default_dosage 케이스 → custom_dosage = NULL 확인
- [ ] tracked.dosage != catalog.default_dosage 케이스 → custom_dosage = tracked.dosage 확인
- [ ] catalog가 setNull로 끊긴 tracked → 마이그레이션 후 custom_* 컬럼에 보존

**Repository:**
- [ ] `insertWithSchedules(draft)` — catalogItemId 필수, 시그니처 컴파일 확인
- [ ] catalog 미존재 catalogItemId 전달 시 FK 에러 (SQLite는 nullable이라 link 실패 시 NULL 저장 — 호출 측 책임)
- [ ] `updateWithSchedules` — schedules 교체 후 catalogItemId 보존 확인

**UI:**
- [ ] 홈 카드 약 이름/카테고리 정상 표시 (catalog seed)
- [ ] 홈 카드 약 이름/카테고리 정상 표시 (user catalog)
- [ ] 캘린더 일자 마크 정상
- [ ] 리포트 통계 정상 (이름 외엔 메타 사용 없음)
- [ ] 드로어 카드 아이콘/색상 정상 (catalog 우선)
- [ ] 상세 화면 표시 정상

---

## 9. Clean Architecture (Flutter Adaptation)

### 9.1 Layer Structure

| Layer | Responsibility | Location |
|-------|---------------|----------|
| **Presentation** | Widget, screen, sheet | `lib/features/*/presentation/`, `lib/core/widgets/` |
| **Application** | Provider, view model (`TrackedMedicationWithSchedules`) | `lib/features/medication/data/*_providers.dart`, repository |
| **Domain** | Drift table 정의, enum, draft struct | `lib/core/database/tables/`, `lib/features/medication/data/*` |
| **Infrastructure** | AppDatabase 연결, 알림 시스템 | `lib/core/database/`, `lib/core/notifications/` |

### 9.2 본 작업 영향 범위 (레이어별)

| Component | Layer | 변경 종류 |
|-----------|-------|-----------|
| `tracked_medications.dart` | Domain | 컬럼 제거 + 컬럼 rename |
| `app_database.dart` | Infrastructure | schemaVersion 7 + onUpgrade |
| `medication_repository.dart` | Application | Draft 시그니처 + insertWithSchedules/updateWithSchedules |
| `*_providers.dart` | Application | display getter caller 정리 (영향 적음, 대부분 m.medication.* → m.display*) |
| 화면 파일들 | Presentation | display* getter 사용 |

---

## 10. Coding Convention Reference

### 10.1 Naming Conventions (본 작업 추가/변경)

| Target | Rule | Example |
|--------|------|---------|
| Override 컬럼 prefix | `custom*` | `customDosage`, `customUnit` |
| FK 컬럼 | tracked 의미는 `medicationId` 유지 (호환), 신규 추가 시 `trackedMedicationId` 권장 | — |
| Draft 필드 | catalogItemId, customDosage, customUnit | — |

### 10.2 Drift Migration Style

- `customStatement` + raw SQL 사용 (v6 패턴 일관)
- PRAGMA foreign_keys OFF → 작업 → ON 패턴 준수
- 신규 테이블은 `{name}_new` 접미사, 작업 후 RENAME
- 인덱스는 swap 후 별도 CREATE INDEX

### 10.3 This Feature's Conventions

| Item | Convention Applied |
|------|-------------------|
| 마이그레이션 SQL | inline customStatement (v6 선례) |
| 백필 알고리즘 | SQL-only (앱 코드 의존 X — onUpgrade 안에서 완결) |
| Caller 마이그레이션 | display* getter 강제, 직참조 grep 0건 (DoD) |
| 파일/변수 rename | 본 PR에선 `medication_repository.dart` 단일 파일 rename, 나머지는 후속 |

---

## 11. Implementation Guide

### 11.1 File Structure

```
lib/
├── core/
│   └── database/
│       ├── app_database.dart                  ← schemaVersion 6→7 + onUpgrade
│       └── tables/
│           └── tracked_medications.dart       ← 컬럼 제거 + rename
├── features/
│   └── medication/
│       ├── data/
│       │   ├── medication_repository.dart     ← Draft 시그니처 + caller 정리
│       │   ├── medication_providers.dart      ← 영향 없음 (선택적 점검)
│       │   ├── intake_repository.dart         ← display name 사용 (현재 m.name 직참조)
│       │   ├── intake_providers.dart          ← 영향 없음
│       │   ├── calendar_providers.dart        ← 영향 없음
│       │   └── reports_providers.dart         ← 영향 없음
│       └── presentation/
│           ├── medication_list_screen.dart    ← display* 마이그레이션
│           ├── medication_detail_screen.dart  ← display* 마이그레이션
│           └── add/
│               ├── medication_add_flow.dart   ← Draft 시그니처 적용
│               └── steps/
│                   └── step2_name.dart        ← catalog 선택/생성 흐름 확정
├── core/
│   └── widgets/
│       └── sheets/
│           ├── bundle_notification_sheet.dart ← display* (간접: BundleMed.name)
│           └── edit_record_sheet.dart         ← display* (medName 인자)
├── core/
│   └── notifications/
│       └── medication_notification_manager.dart ← med.name → display 변환
└── features/
    ├── home/presentation/home_screen.dart        ← display* 마이그레이션
    └── calendar/presentation/calendar_screen.dart ← display* 마이그레이션
└── mockups/
    ├── mockup_drawer_card.dart                ← Draft 시그니처 dev only
    └── mockup_drawer_screen.dart              ← Draft 시그니처 dev only
```

### 11.2 Implementation Order

1. [ ] **Schema 변경** — `tracked_medications.dart` 컬럼 제거 + rename
2. [ ] **Drift 코드 재생성** — `dart run build_runner build --delete-conflicting-outputs`
3. [ ] **Migration SQL** — `app_database.dart` schemaVersion 7 + onUpgrade(from < 7) 추가
4. [ ] **Repository Draft 시그니처** — `TrackedMedicationDraft` + `insertWithSchedules` / `updateWithSchedules`
5. [ ] **View model getter** — `displayName/Category/Shape/ColorHex/IconKey` 폴백 텍스트 적용
6. [ ] **Caller 마이그레이션** — 13파일 display* 적용 (체크리스트 §11.3)
7. [ ] **flutter analyze** — clean 확인
8. [ ] **수동 마이그레이션 테스트** — v6 DB → v7 upgrade
9. [ ] **회귀 테스트** — 홈/캘린더/리포트/드로어/상세

### 11.3 Caller 체크리스트 (13파일)

| # | 파일 | 현재 직참조 | 마이그레이션 방향 | 비고 |
|---|------|-------------|------------------|------|
| 1 | `lib/core/notifications/medication_notification_manager.dart` | `TrackedMedication med` 파라미터, `med.name` 사용 | 시그니처를 `TrackedMedicationWithSchedules`로 변경 또는 `(med, catalog)` 페어 전달 | 알림 본문에 약 이름 들어감 — display 사용 필수 |
| 2 | `lib/core/widgets/sheets/bundle_notification_sheet.dart` | `BundleMed.name` | 호출자가 display 전달 (sheet는 그대로) | sheet는 dumb component, 변경 없음 |
| 3 | `lib/core/widgets/sheets/edit_record_sheet.dart` | `medName` 인자 | 호출자가 display 전달 | sheet 변경 없음 |
| 4 | `lib/features/home/presentation/home_screen.dart` | `dose.medicationName`(DoseInstance에 이미 들어감) | DoseInstance.medicationName 생성 시 display 사용 | `intake_repository.dart`의 `computeDosesForDay`에서 변환 |
| 5 | `lib/features/calendar/presentation/calendar_screen.dart` | `dose.medicationName` | 동일 | 동일 |
| 6 | `lib/features/catalog/data/catalog_repository.dart` | catalog 직접 다룸 | 영향 없음 | catalog ↔ tracked 분리 후 catalog만 다루는 repo |
| 7 | `lib/features/medication/data/intake_repository.dart` | `m.name`, `quantityOf(m)` | `m.displayName` 변환, quantity는 `customDosage ?? catalog.defaultDosage` 사용 | DoseInstance 빌드 시점에 변환 |
| 8 | `lib/features/medication/data/medication_repository.dart` | tracked 컬럼 INSERT/UPDATE | Draft 시그니처 변경 + companion 정리 | 핵심 변경 |
| 9 | `lib/features/medication/presentation/medication_detail_screen.dart` | `data.medication.name/category/dosage/...` | `data.displayName/...` | UI 그대로 |
| 10 | `lib/features/medication/presentation/medication_list_screen.dart` | `m.medication.name`, `m.medication.category`, `m.medication.memo` 등 | `m.displayName`/`m.displayCategory`. memo는 그대로. | 검색 필터도 display 기준 |
| 11 | `lib/features/medication/presentation/add/medication_add_flow.dart` | `m.medication.name/category/dosage/...` (수정 시 prefill) | `m.displayName/...` + Draft에 catalogItemId 명시 | 수정 플로우 시 기존 catalog 유지 |
| 12 | `lib/features/medication/presentation/add/steps/step2_name.dart` | step2가 name 입력 받음 | catalog 검색 → 선택 또는 user catalog 생성 → catalogItemId 보유. name 자체 입력은 catalog 생성 경로로 | 핵심 UX 변경 (UI는 동일) |
| 13 | `lib/mockups/mockup_drawer_card.dart`, `mockup_drawer_screen.dart` | Mock TrackedMedication 생성 | Mock 데이터를 (catalog, tracked) 페어로 생성 | dev only, 우선순위 낮음 |

**검증 명령:**
```bash
# 직참조 0건 확인
grep -rn "\.medication\.\(name\|category\|shape\|colorHex\|iconKey\|dosage\|unit\)" \
  lib --include="*.dart" | grep -v ".g.dart"
# 결과: 0건 이어야 함
```

### 11.4 Drift 코드 재생성

```bash
dart run build_runner build --delete-conflicting-outputs
```
- 생성물 `app_database.g.dart`의 `TrackedMedications` 클래스가 신규 스키마 반영
- companion 클래스도 자동 업데이트 (`name`/`category` 등 제거됨)

### 11.5 마이그레이션 수동 테스트 절차

1. `git stash` (현재 변경 보존)
2. 앱 빌드 → 실기기 설치 (v6 schemaVersion)
3. 약 3건 등록 (seed catalog 1, user catalog 2)
4. 각 약마다 schedule + 일부 markTaken
5. `git stash pop` → v7 코드로 재빌드 → 실기기 hot restart
6. 다음 확인:
   - 약 3건 모두 보임 (이름/카테고리 정상)
   - schedules 모두 보임
   - intake_logs 모두 보임 (history 보존)
   - reports 통계 정상 (이전과 동일)

---

## 12. Rollback Plan

| 상황 | Rollback 방법 |
|------|---------------|
| 마이그레이션 SQL 실패 | onUpgrade가 도중 throw → Drift는 트랜잭션 자동 rollback. 신규 테이블만 drop하면 v6 그대로. |
| flutter analyze 실패 | PR 머지 차단. 코드 revert. |
| 수동 회귀 실패 | git revert + 사용자에게 핫픽스 (v7 → v6 다운그레이드는 불가, 새 컬럼만 ALTER TABLE ADD 후 백필) |

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 0.1 | 2026-05-21 | Initial draft — Migration SQL, 백필 알고리즘, caller 체크리스트 13파일 | 정성훈 |
