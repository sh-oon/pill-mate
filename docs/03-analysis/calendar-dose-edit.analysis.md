---
template: analysis
version: 1.2
feature: calendar-dose-edit
date: 2026-05-22
author: 정성훈 (gap-detector agent)
project: pill_mate
appVersion: 3.0.0+7
---

# calendar-dose-edit Analysis Report

> **Analysis Type**: Gap Analysis (Design vs Implementation)
>
> **Project**: pill_mate (Flutter)
> **Version**: 3.0.0+7
> **Analyst**: 정성훈 (with bkit:gap-detector)
> **Date**: 2026-05-22
> **Plan Doc**: [calendar-dose-edit.plan.md](../01-plan/features/calendar-dose-edit.plan.md)
> **Design Doc**: [calendar-dose-edit.design.md](../02-design/features/calendar-dose-edit.design.md)
> **Do Doc**: [calendar-dose-edit.do.md](./03-do/calendar-dose-edit.do.md)

---

## 1. Analysis Overview

### 1.1 Purpose
Design 문서와 실제 구현 코드를 비교하여 FR/Design Element 충족 여부, deviation, gap, 회귀 영향을 측정한다.

### 1.2 Scope
- **Design**: `docs/02-design/features/calendar-dose-edit.design.md`
- **Implementation**:
  - `lib/core/widgets/sheets/edit_record_sheet.dart`
  - `lib/features/calendar/presentation/calendar_screen.dart`
  - `lib/features/home/presentation/home_screen.dart`
  - `lib/features/medication/data/intake_repository.dart`
- **Do deviations**: `docs/03-do/calendar-dose-edit.do.md` §1.3 (invalidate 정책 정정)
- **Date**: 2026-05-22

---

## 2. Gap Analysis (Design vs Implementation)

### 2.1 Functional Requirements (Plan §5.1)

| ID | Status | Evidence (file:line) | Notes |
|----|:------:|----------------------|-------|
| FR-01 (sheet props 추가) | ✅ | `edit_record_sheet.dart:38-47` | `dateLabel`, `currentStatus`, `allowMissed=false` 모두 default 가능 |
| FR-02 (enum +`markMissed`) | ✅ | `edit_record_sheet.dart:15` | 순서: `keep, markTaken, markMissed` |
| FR-03 (본문 + 액션 row 분기) | ✅ | `edit_record_sheet.dart:48` (label fallback), `:150-195` (action specs) | §5.1 표 5케이스 모두 커버 |
| FR-04 (`_RecordCard` tap) | ✅ | `calendar_screen.dart:369-431` | Material+InkWell wrap, `onTap` 필수 prop |
| FR-05 (미래 가드 + SnackBar) | ✅ | `calendar_screen.dart:106-112` | `isAfter(now)` → "아직 예정된 복용입니다" + return |
| FR-06 (sheet show with relativeLabel) | ✅ | `calendar_screen.dart:114-122` | `allowMissed: true`, `currentStatus`, `dateLabel: _relativeLabel(...)` |
| FR-07 (mark 분기) | ✅ | `calendar_screen.dart:128-146` + `home_screen.dart:228-246` | switch 4 case (markTaken/markMissed/keep/null) |
| FR-08 (invalidate set) | ✅ (acknowledged deviation) | `do.md §1.3` | StreamProvider 자동 전파로 명시 invalidate 대체 — 의도된 정정 |
| FR-09 (성공 SnackBar 분기) | ✅ | `calendar_screen.dart:135,142,156-157` + `home_screen.dart:235,242,256-257` | taken/missed 메시지 분기 |
| FR-10 (Home 정합화) | ✅ | `home_screen.dart:204-258` | Calendar와 동일 구조 — dateLabel 동적, allowMissed=true, markMissed 분기 |
| FR-11 (과거 missed 격상, read-only) | ✅ | `intake_repository.dart:259-273` | `isPastDay && !beforeStart && !hasLog` → missed. `beforeStart` 가드 보존. log row 미생성 |
| FR-12 (회귀 가드) | ✅ | past-dose-edit/catalog-phase-2c 파일 미수정 | `past_doses_backfill_sheet.dart`, `medication_add_flow.dart`, `past_dose_slot.dart` 불변 |

### 2.2 Design Element Verification

| Design Section | Status | Evidence |
|---|:--:|---|
| §3.1 enum 순서 | ✅ | `edit_record_sheet.dart:15` |
| §3.2 props + `@Deprecated yesterday` | ✅ | `edit_record_sheet.dart:38-47` |
| §3.2 `dateLabel ?? (yesterday ? '어제' : '오늘')` fallback | ✅ | `edit_record_sheet.dart:48` |
| §3.3 `_relativeLabel` — Calendar | ✅ | `calendar_screen.dart:160-170` |
| §3.3 `_relativeLabel` — Home (line-for-line 동일) | ✅ | `home_screen.dart:260-270` |
| §3.4 `computeDosesForDay` diff | ✅ | `intake_repository.dart:259-273` — `beforeStart` 가드가 `isPastDay`보다 우선 |
| §5.1 액션 row 5케이스 분기 | ✅ | `edit_record_sheet.dart:150-195` |
| §5.5 `_RecordCard` Material+InkWell | ✅ | `calendar_screen.dart:376-387` |
| §11.3 Calendar pseudocode 구조 일치 | ✅ | `calendar_screen.dart:105-158` |
| §11.4 Home pseudocode 구조 일치 | ✅ | `home_screen.dart:204-258` |
| §11.5 `_resolveLeftAction`/`_resolveRightAction` 분리 | ✅ | `edit_record_sheet.dart:150-195` |

### 2.3 Component Structure

| Design Component | Implementation | Status |
|---|---|:--:|
| `EditRecordSheet` 확장 | `lib/core/widgets/sheets/edit_record_sheet.dart` | ✅ |
| `_RecordCard` tap-aware | `lib/features/calendar/presentation/calendar_screen.dart:369-431` | ✅ |
| `_CalendarScreenState._openEditSheet` | 동 파일 :100-158 | ✅ |
| `_HomeScreenState._openEditSheet` 정합화 | `lib/features/home/presentation/home_screen.dart:204-258` | ✅ |
| `_relativeLabel` ×2 | calendar:160-170 + home:260-270 | ✅ (중복 — §3.3 명시) |
| `computeDosesForDay` 과거 missed 격상 | `lib/features/medication/data/intake_repository.dart:259-273` | ✅ |

### 2.4 Match Rate Summary

```
┌─────────────────────────────────────────────┐
│  Overall Match Rate: 100%                   │
├─────────────────────────────────────────────┤
│  ✅ Match (FR-01~FR-12):     12 / 12        │
│  ✅ Design Elements:         11 / 11        │
│  ⚠️ Acknowledged deviations:  3 (all intent)│
│  ❌ Unintentional gaps:       0             │
└─────────────────────────────────────────────┘
```

---

## 3. Code Quality Analysis

### 3.1 Static Analysis
| Check | Result |
|---|---|
| `flutter analyze` | **No issues found** (do Step 6) |
| 신규 warning | 0 |
| 기존 warning | 0 |

### 3.2 Code Smells

| Type | File | Severity | Description |
|---|---|---|---|
| Duplicate code | calendar_screen.dart + home_screen.dart | 🟢 Low | `_openEditSheet` ~50줄 + `_relativeLabel` ~10줄 중복 — Design §3.3에서 명시 수용("v1은 각 screen private function, 중복 발견 시 ENH") |
| Inconsistent style | mounted vs context.mounted | 🟢 Low | Calendar는 `mounted` (State getter), Home은 `context.mounted` (parameter). 각자 scope에서 올바르나 스타일 불일치 |
| Backward-compat fallback | edit_record_sheet.dart:271-272 | 🟢 Low | `currentStatus: null` fallback("놓침으로 표시됨") — 현 모든 호출자는 currentStatus 명시. 향후 정리 가능 |

### 3.3 Security Issues
N/A — 로컬 Drift DB만, 네트워크/암호화/인증 무관.

---

## 4. Performance Analysis
N/A — 본 변경은 sheet 호출 + repo upsert + stream 자동 전파. 측정 가치 있는 경계 없음(기존 `mark` API 사용).

---

## 5. Test Coverage

### 5.1 Static
- [x] 모든 FR code path 정적으로 존재함 확인 (gap-detector verified)

### 5.2 Manual (사용자 수동)
Design §8.2 TC-01 ~ TC-15 — **user-pending** (실기기/에뮬레이터 필요)

| TC | 정적 code path 존재? | 비고 |
|---|:--:|---|
| TC-01/02/03 (Calendar toggle) | ✅ | `calendar_screen.dart:128-146` |
| TC-04 (오늘 toggle) | ✅ | 같은 path |
| TC-05 (미래 가드) | ✅ | `:107-112` |
| TC-06/07/08 (과거 missed + toggle) | ✅ | `intake_repository.dart:259-273` (read-only 확인) |
| TC-09/10/11 (UI 자동 갱신) | ⚠️ runtime 확인 필요 | StreamProvider 자동 전파 의존 |
| TC-12 (Home 정합화) | ✅ | `home_screen.dart:204-258` |
| TC-13 (호환성) | ✅ | `@Deprecated yesterday` fallback + statusLabel fallback |
| TC-14 (startDate 이전 슬롯) | ✅ | `beforeStart` 가드 `isPastDay` 우선 |
| TC-15 (race 무해) | ⚠️ runtime | Drift upsert 의존 |

---

## 6. Clean Architecture Compliance

### 6.1 Layer 배치
| Component | Layer | Location | Status |
|---|---|---|:--:|
| `EditRecordSheet` | Presentation (cross-cutting) | `lib/core/widgets/sheets/` | ✅ |
| `_RecordCard`, `_CalendarScreenState._openEditSheet` | Presentation (feature) | `lib/features/calendar/presentation/` | ✅ |
| `_HomeScreenState._openEditSheet` | Presentation (feature) | `lib/features/home/presentation/` | ✅ |
| `computeDosesForDay` | Data (free function) | `lib/features/medication/data/` | ✅ |

### 6.2 의존 방향
- Sheet → Data 직접 호출 없음 ✅
- Screen → Repository(`intakeRepositoryProvider`)를 통해서만 mark 호출 ✅
- 신규 import 추가: Calendar에 `edit_record_sheet.dart` + `intake_providers.dart`만 추가 — Data 직접 import 없음 ✅

### 6.3 Architecture Score
```
┌─────────────────────────────────────────────┐
│  Architecture Compliance: 100%               │
├─────────────────────────────────────────────┤
│  ✅ Correct layer placement: 4/4 components  │
│  ✅ Dependency violations:   0               │
└─────────────────────────────────────────────┘
```

---

## 7. Convention Compliance

### 7.1 Naming
| Category | Convention | Status |
|---|---|:--:|
| Dart 파일명 | snake_case.dart | ✅ 4/4 |
| Widget class | PascalCase | ✅ `EditRecordSheet`, `_RecordCard`, `_ActionSpec`, `_Header`, `_MedInfoCard` |
| Function/method | camelCase | ✅ `_openEditSheet`, `_relativeLabel`, `_resolveLeftAction`, etc. |
| Enum | PascalCase + camelCase 멤버 | ✅ `EditRecordChoice.{keep, markTaken, markMissed}` |
| Static factory | `show(BuildContext, {...})` | ✅ |
| `@Deprecated` | `yesterday` | ✅ |
| `AppColors.*` 토큰 | hex literal 금지 | ✅ (기존 `barrierColor: const Color(0x80141428)` 예외는 본 feature 도입 아님) |

### 7.2 Sheet 컨벤션 (기존 패턴 준수)
- [x] Container padding `EdgeInsets.fromLTRB(22, 18, 22, 24 + viewInsets.bottom)`
- [x] handle bar `AppColors.borderHairline` 36×4
- [x] Header / Body / Action Row 구조
- [x] `AppButton(variant: ..., fullWidth: true)` 2버튼 row

### 7.3 Convention Score
```
┌─────────────────────────────────────────────┐
│  Convention Compliance: 100%                 │
├─────────────────────────────────────────────┤
│  Naming:           100%                      │
│  File structure:   100%                      │
│  Sheet pattern:    100%                      │
└─────────────────────────────────────────────┘
```

---

## 8. Overall Score

```
┌─────────────────────────────────────────────┐
│  Overall Score: 100/100                      │
├─────────────────────────────────────────────┤
│  Design Match:        100 points             │
│  Code Quality:        100 points             │
│  Architecture:        100 points             │
│  Convention:          100 points             │
│  Security:            N/A (no surface)       │
│  Performance:         N/A (no boundary)      │
│  Testing (static):    100 points             │
│  Testing (manual):    user-pending           │
└─────────────────────────────────────────────┘
```

---

## 9. Deviations (Intentional)

| # | Deviation | Type | Reasoning |
|---|---|:--:|---|
| 1 | 명시 `ref.invalidate(...)` 호출 없음 | Acknowledged (do §1.3) | `dayDoses/monthMarks/todayLogs`가 모두 StreamProvider — Drift stream 자동 전파. 명시 호출 redundant. `todayCounts/todayNextDose/recentMissed`는 `todayLogs` 의존 → 자동 전파 |
| 2 | Design `nextDoseProvider` → 실제 `todayNextDoseProvider` | Documentation fix (do §1.3) | Design의 provider 명 오기 정정 — 동작 영향 0 |
| 3 | 미래 가드 SnackBar 전 `mounted` 체크 없음 (entry 즉시 호출) | Minor, low-risk | async 경계 미통과 — 동기적으로 안전 |

---

## 10. Gap List

🔴 **Critical**: 없음

🟡 **Medium**: 없음

🟢 **Low**:
1. **Duplicate `_openEditSheet` + `_relativeLabel`** (Calendar/Home 각각). Design §3.3에서 명시 수용. 세 번째 호출자 등장 시 `lib/core/utils/relative_date.dart` + mixin 추출 ENH.
2. **`mounted` vs `context.mounted` 스타일 불일치** (Calendar/Home). 각각 정확하나 통일 가능. 선택적.
3. **`_statusLabel: null` fallback** (edit_record_sheet.dart:271-272). 현 모든 호출자는 currentStatus 명시. 향후 legacy 호출자 없음이 확실해지면 제거 가능.

---

## 11. Recommended Actions

### 11.1 즉시
없음 — Match Rate 100%로 Critical/Medium 항목 부재.

### 11.2 다음 단계
1. **사용자 manual TC** — Design §8.2 TC-01 ~ TC-15 + §8.3 회귀 체크. TC-09/10/11(StreamProvider 자동 전파 latency)와 TC-15(race window)는 실기기 확인 필수.
2. **`/pdca report calendar-dose-edit`** — Match Rate ≥ 90% 충족, 완료 보고서 생성.
3. **Release note** (Plan §7 / Design §6 반영): 과거 날짜 pending→missed 자동 격상이 weekly/monthly report 카운트에 의도된 변화를 일으킴을 사용자 공지.

### 11.3 Long-term (선택 ENH)
- `_relativeLabel` 추출 (`lib/core/utils/relative_date.dart`) — 세 번째 호출자 등장 시
- `mounted` 스타일 통일 — code-style ENH
- `_statusLabel: null` fallback 제거 — legacy 정리 ENH

---

## 12. Design Document Updates Needed

| Item | 처리 |
|---|---|
| §11.6 Invalidate set | do §1.3에서 정정 — Design은 historical reference로 보존 |
| §3.3 provider 명 오기 (`nextDoseProvider` → `todayNextDoseProvider`) | do §1.3에서 명시 정정 |

> 둘 다 do 문서에서 deviation을 명시 기록했으므로 Design 본문 수정은 선택. 후속 enhancement에서 design을 손볼 때 같이 정리.

---

## 13. Next Steps

- [x] Gap analysis 완료 (Match Rate 100%)
- [ ] 사용자 manual TC §8.2 TC-01~TC-15 + §8.3 회귀
- [ ] `/pdca report calendar-dose-edit` (Match Rate ≥ 90% 충족)
- [ ] Release note 작성 (과거 missed 자동 격상)

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 0.1 | 2026-05-22 | Initial gap analysis (Match Rate 100%) | 정성훈 + bkit:gap-detector |
