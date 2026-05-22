---
template: do
version: 1.0
feature: catalog-phase-2c
date: 2026-05-21
author: 정성훈 <shjung@surromind.ai>
project: pill_mate
version_app: 1.0.0+4
---

# catalog-phase-2c Implementation Guide

> **Summary**: schemaVersion 6→7 마이그레이션으로 `tracked_medications`에서 catalog 중복 메타 컬럼 제거 + caller 13파일 `display*` getter 마이그레이션.
>
> **Project**: pill_mate
> **Version**: 1.0.0+4
> **Author**: 정성훈
> **Date**: 2026-05-21
> **Status**: In Progress
> **Design Doc**: [catalog-phase-2c.design.md](../02-design/features/catalog-phase-2c.design.md)
> **Plan Doc**: [catalog-phase-2c.plan.md](../01-plan/features/catalog-phase-2c.plan.md)

---

## 1. Pre-Implementation Checklist

- [x] Plan reviewed (`docs/01-plan/features/catalog-phase-2c.plan.md`)
- [x] Design reviewed (`docs/02-design/features/catalog-phase-2c.design.md`)
- [x] 환경 확인: Flutter SDK (fvm), drift, build_runner, riverpod
- [ ] `git status` 클린 상태에서 시작
- [ ] 실기기 또는 시뮬레이터에 v6 schemaVersion 빌드 설치 (마이그레이션 테스트용)

---

## 2. Implementation Order

> Design §11.2 순서 그대로. 각 단계는 commit 단위로 묶을 것 권장.

### 2.1 Phase 1: Schema & Migration (Foundation)

| # | Task | File | Status |
|:--:|------|------|:------:|
| 1 | `TrackedMedications` 컬럼 제거 + rename (`dosage→customDosage`, `unit→customUnit`) | `lib/core/database/tables/tracked_medications.dart` | ☐ |
| 2 | Drift 코드 재생성 — `dart run build_runner build --delete-conflicting-outputs` | `lib/core/database/app_database.g.dart` | ☐ |
| 3 | schemaVersion 6→7 + `onUpgrade(from < 7)` 추가 (Design §3.3 SQL 6단계) | `lib/core/database/app_database.dart` | ☐ |

> **체크포인트 1**: `flutter analyze`가 컴파일 에러를 광범위하게 띄움 (caller가 사라진 컬럼 참조). 정상.

### 2.2 Phase 2: Repository & View Model

| # | Task | File | Status |
|:--:|------|------|:------:|
| 4 | `TrackedMedicationDraft` 필드 변경: `name/category/shape/colorHex/iconKey` 제거, `catalogItemId` 필수, `customDosage/customUnit` rename | `lib/features/medication/data/medication_repository.dart` | ☐ |
| 5 | `insertWithSchedules` / `updateWithSchedules` 정리: catalog는 호출자가 사전 resolve, 컴패니언 신규 컬럼 반영 | 동상 | ☐ |
| 6 | `TrackedMedicationWithSchedules.displayName` 등 폴백 텍스트 적용 (catalog NULL 시 `'(이름 없음)'`) | 동상 | ☐ |
| 7 | `_resolveOrCreateCatalog` — 외부에서 호출 가능하도록 public API화 (등록 플로우 step2에서 사용) | 동상 | ☐ |

> **체크포인트 2**: repository 컴파일 통과. 아직 caller는 깨진 상태.

### 2.3 Phase 3: Caller Migration (13파일)

Design §11.3 체크리스트. 우선순위 순:

#### 3-A. 핵심 데이터 레이어 (먼저, 다른 caller 의존)

| # | Task | File | Status |
|:--:|------|------|:------:|
| 8 | DoseInstance 빌드 시 `display*` 사용 | `lib/features/medication/data/intake_repository.dart` | ☐ |
| 9 | 알림 본문에 catalog name 사용 (시그니처를 `TrackedMedicationWithSchedules` 또는 (med, catalog) 페어로) | `lib/core/notifications/medication_notification_manager.dart` | ☐ |

#### 3-B. UI 화면 (병렬 가능)

| # | Task | File | Status |
|:--:|------|------|:------:|
| 10 | 드로어 카드 `m.displayName/displayCategory` 등 | `lib/features/medication/presentation/medication_list_screen.dart` | ☐ |
| 11 | 상세 화면 동일 | `lib/features/medication/presentation/medication_detail_screen.dart` | ☐ |
| 12 | 등록 플로우 — step2에서 catalog 검색/선택, Draft에 `catalogItemId` 채우기 | `lib/features/medication/presentation/add/medication_add_flow.dart`, `add/steps/step2_name.dart` | ☐ |
| 13 | 홈/캘린더는 DoseInstance.medicationName 사용 중 — Step 8에서 변환되므로 변경 없을 수도. grep 후 확정 | `lib/features/home/presentation/home_screen.dart`, `lib/features/calendar/presentation/calendar_screen.dart` | ☐ |

#### 3-C. Dev only (낮은 우선순위)

| # | Task | File | Status |
|:--:|------|------|:------:|
| 14 | Mock 데이터를 (catalog, tracked) 페어로 재구성 | `lib/mockups/mockup_drawer_card.dart`, `lib/mockups/mockup_drawer_screen.dart` | ☐ |

> **체크포인트 3**: `flutter analyze --fatal-warnings` clean. grep 검증:
> ```bash
> grep -rn "\.medication\.\(name\|category\|shape\|colorHex\|iconKey\)" \
>   lib --include="*.dart" | grep -v ".g.dart"
> # 결과: 0건
> ```

### 2.4 Phase 4: Validation

| # | Task | Method | Status |
|:--:|------|--------|:------:|
| 15 | `flutter analyze --fatal-warnings` clean | CI/local | ☐ |
| 16 | `flutter test` 기존 테스트 통과 | CI/local | ☐ |
| 17 | v6 DB → v7 마이그레이션 수동 테스트 (Design §11.5 절차) | 실기기 manual | ☐ |
| 18 | 회귀: 홈 / 캘린더 / 리포트 / 드로어 / 상세 화면 정상 동작 | 실기기 manual | ☐ |
| 19 | 회귀: 새 약 등록 → 홈에서 표시 → 마크 → 캘린더/리포트 반영 | 실기기 manual | ☐ |

---

## 3. Key Files to Modify

### 3.1 Schema / Migration

| File | Changes |
|------|---------|
| `tables/tracked_medications.dart` | 컬럼 5개 drop, 2개 rename, 2개 신규 (`customDosage`, `customUnit`) |
| `app_database.dart` | `schemaVersion: 6 → 7`, `onUpgrade`에 `if (from < 7)` 블록 추가 |
| `app_database.g.dart` | build_runner 재생성 |

### 3.2 Application

| File | Changes |
|------|---------|
| `medication_repository.dart` | `TrackedMedicationDraft` 시그니처, insert/update, display 폴백 텍스트, `_resolveOrCreateCatalog` public API화 |

### 3.3 Caller (display*로 마이그레이션)

`medication_list_screen.dart`, `medication_detail_screen.dart`, `medication_add_flow.dart`, `step2_name.dart`, `intake_repository.dart`, `medication_notification_manager.dart`, `mockup_*` (2건).

> **참고**: `home_screen`, `calendar_screen`은 `DoseInstance.medicationName`을 통해 간접 접근. `intake_repository.dart`만 고치면 자동 반영 가능성 높음. grep으로 확정.

---

## 4. Dependencies

추가 dependency 없음. 기존 `drift`, `flutter_riverpod`, `uuid` 사용.

```bash
# Drift 코드 재생성 (필수)
dart run build_runner build --delete-conflicting-outputs

# 정적 검증
fvm flutter analyze

# 테스트
fvm flutter test
```

---

## 5. Implementation Notes

### 5.1 Design Decisions Reference (Design §6.2)

| Decision | Choice | Rationale |
|----------|--------|-----------|
| 마이그레이션 방식 | new table + swap | SQLite ALTER 한계 + v6 선례 |
| catalog 백필 | tracked 메타 → catalog로 끌어올림 + dedupe | SSOT 통일 |
| override 컬럼명 | `customDosage/customUnit` rename | 의미 명확화 |
| caller 마이그레이션 시점 | 컬럼 제거와 동시 | 컴파일 에러로 누락 방지 |
| 알림 payload | 변경 없음 | 호환성 유지 |

### 5.2 Things to Avoid

- ❌ `tracked.name/category/shape/colorHex/iconKey` 잔여 참조 (컴파일 에러로 잡힘)
- ❌ 마이그레이션 도중 `PRAGMA foreign_keys = ON` 상태 (백필 단계에서 INSERT 깨질 수 있음)
- ❌ catalog dedupe 누락 (같은 (name, category) 중복 생성 → 데이터 노이즈)
- ❌ `DoseInstance.medicationName` 빌드 시 `m.name` 직참조 (display 사용해야 catalog 갱신 반영)

### 5.3 Architecture Checklist

- [x] **Domain (Drift table)** 변경 — caller는 컴파일러가 강제
- [x] **Application (Repository/ViewModel)** 변경 — display getter 단일 경로
- [x] **Infrastructure (DB onUpgrade)** 변경 — 자동 마이그레이션
- [x] **Presentation** 변경 최소 — UI 로직 무변경, 표현값만 display로

### 5.4 Convention Checklist

- [x] Drift `customStatement` + raw SQL (v6 패턴 일관)
- [x] PRAGMA OFF → 작업 → ON 패턴
- [x] 신규 테이블 `{name}_new` 접미사
- [x] override prefix `custom*`

---

## 6. Testing Checklist

### 6.1 Manual Migration Test (Design §11.5)

1. [ ] v6 코드(현재 main)로 빌드 → 실기기 설치
2. [ ] 약 3건 등록 (catalog seed 1개, user 입력 2개)
3. [ ] 각 약마다 schedule 등록 + 일부 markTaken
4. [ ] v7 코드(이 PR)로 hot restart (`fvm flutter run --hot`이 아닌 full restart)
5. [ ] 다음 확인:
   - [ ] 약 3건 모두 보임
   - [ ] 약 이름/카테고리/아이콘 정상
   - [ ] schedules 모두 보임
   - [ ] intake history 보존
   - [ ] 리포트 통계 v6와 동일

### 6.2 회귀 — Happy Path

- [ ] 신규 등록 (step1 → step2 catalog 선택 → step3 알람) → drawer 카드 표시
- [ ] 홈에서 “먹었어요” 탭 → intake_log 기록 → 캘린더에 mark
- [ ] 리포트 통계 갱신 확인
- [ ] medication detail → 수정 → 저장 → 변경 반영

### 6.3 Edge Cases

- [ ] catalog가 setNull로 끊긴 legacy tracked → `'(이름 없음)'` 폴백 + 다른 화면도 깨지지 않음
- [ ] user catalog 생성 → 같은 (name, category) 중복 등록 시 dedupe 동작

---

## 7. Progress Tracking

### 7.1 Phase 진행

| Phase | Status | Date | Notes |
|-------|:------:|------|-------|
| Schema & Migration (1-3) | ☐ | — | — |
| Repository & ViewModel (4-7) | ☐ | — | — |
| Caller Migration (8-14) | ☐ | — | — |
| Validation (15-19) | ☐ | — | — |

### 7.2 Blockers

| Issue | Impact | Resolution |
|-------|--------|------------|
| (none yet) | — | — |

---

## 8. Post-Implementation

### 8.1 Self-Review Checklist

- [ ] Design 문서 §3.3 SQL 그대로 반영
- [ ] caller 직참조 0건 (grep 검증)
- [ ] flutter analyze clean
- [ ] 실기기 마이그레이션 테스트 통과
- [ ] commit 메시지 — Phase 2C 명시

### 8.2 Ready for Check Phase

모든 항목 완료 시:
```bash
/pdca analyze catalog-phase-2c
```

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 0.1 | 2026-05-21 | Initial implementation guide — 19 task checklist | 정성훈 |
