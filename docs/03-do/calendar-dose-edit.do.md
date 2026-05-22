---
template: do
version: 1.0
feature: calendar-dose-edit
date: 2026-05-22
author: 정성훈
project: pill_mate
appVersion: 3.0.0+7
---

# calendar-dose-edit Implementation Guide

> **Summary**: Calendar `_RecordCard` tap → `EditRecordSheet`(확장) 사후 편집(taken↔missed) + Home 정합화 + `computeDosesForDay` 과거 missed 격상(read-only). 신규 파일 0, 수정 4파일.
>
> **Project**: pill_mate (Flutter)
> **Version**: 3.0.0+7
> **Author**: 정성훈
> **Date**: 2026-05-22
> **Status**: In Progress
> **Design Doc**: [calendar-dose-edit.design.md](../02-design/features/calendar-dose-edit.design.md)

---

## 1. Pre-Implementation Checklist

### 1.1 Documents Verified
- [x] Plan: `docs/01-plan/features/calendar-dose-edit.plan.md`
- [x] Design: `docs/02-design/features/calendar-dose-edit.design.md`

### 1.2 Environment
- [x] Flutter SDK 활성 (pubspec.yaml: pill_mate 3.0.0+7)
- [x] Drift `app_database` 정상

### 1.3 Provider 사실 정정 (Design §11.6 후속)
- `dayDosesProvider`/`monthMarksProvider`/`todayLogsProvider`는 모두 **StreamProvider** — Drift stream이 underlying table 변경 시 자동 emit. `IntakeRepository.mark` 후 명시 `ref.invalidate(...)` 호출 **불필요** (redundant).
- `todayCountsProvider`/`todayNextDoseProvider`/`recentMissedProvider`는 `todayLogsProvider` 의존 — 자동 전파.
- 따라서 구현에서는 mark → SnackBar 만으로 충분. invalidate set 코드는 빼고, Design §11.6는 historical reference로 보존.
- provider 이름 정정: Design의 `nextDoseProvider` → 실제는 `todayNextDoseProvider`.

---

## 2. Implementation Order (Design §11.2)

| Step | Task | File | Status |
|:--:|------|------|:--:|
| 1 | `EditRecordSheet` props/enum/액션 분기 확장 | `lib/core/widgets/sheets/edit_record_sheet.dart` | ☐ |
| 2 | `_RecordCard` tap-aware (InkWell wrap) | `lib/features/calendar/presentation/calendar_screen.dart` | ☐ |
| 3 | Calendar `_openEditSheet` + `_relativeLabel` 신규 | 동 파일 | ☐ |
| 4 | `computeDosesForDay` 과거 missed 격상 분기 | `lib/features/medication/data/intake_repository.dart` | ☐ |
| 5 | Home `_openEditSheet` 정합화 + `_relativeLabel` 복제 | `lib/features/home/presentation/home_screen.dart` | ☐ |
| 6 | `flutter analyze` 신규 0 확인 | — | ☐ |
| 7 | Manual TC §8.2 TC-01 ~ TC-15 + 회귀 §8.3 | 사용자 수동 | ☐ |

---

## 3. Files Changed

| File | Type | Lines (예상) |
|------|------|------:|
| `lib/core/widgets/sheets/edit_record_sheet.dart` | modify | +60 / -20 |
| `lib/features/calendar/presentation/calendar_screen.dart` | modify | +90 / -10 |
| `lib/features/home/presentation/home_screen.dart` | modify | +70 / -15 |
| `lib/features/medication/data/intake_repository.dart` | modify | +6 / -2 |

> 신규 파일 없음.

---

## 4. Dependencies

추가 패키지 없음 — 기존 `flutter_riverpod`/`drift`/내부 widget만 사용.

---

## 5. Implementation Notes

### 5.1 Design Decisions Reference
| Decision | Choice |
|----------|--------|
| Sheet 확장 방식 | Approach A (EditRecordSheet props/enum 확장) |
| 액션 row 분기 | currentStatus×allowMissed 5케이스 (Design §5.1) |
| 미래 가드 | `_openEditSheet` 진입 즉시 검사 |
| 과거 missed 격상 | read-only 계산 (log 미생성) |
| invalidate | **자동 stream 전파에 의존** — 명시 호출 제거 (do §1.3 참조) |

### 5.2 Things to Avoid
- [ ] `yesterday` flag 신규 사용 (deprecated — `dateLabel` 사용)
- [ ] hex literal (`AppColors.*` 사용)
- [ ] mark 후 명시 invalidate (자동 stream으로 충분)
- [ ] `print` (`debugPrint` 또는 catch에서 SnackBar만)

---

## 6. Testing Checklist

### 6.1 Static
- [ ] `flutter analyze` clean (신규 0)

### 6.2 Manual (사용자)
- Design §8.2 TC-01 ~ TC-15
- Design §8.3 회귀 체크 (past-dose-edit / catalog-phase-2c / Home highlight / Home BundleNotificationSheet)

---

## 7. Ready for Check

전 step 완료 후:
```bash
/pdca analyze calendar-dose-edit
```

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 0.1 | 2026-05-22 | Initial implementation start (Design §11.6 invalidate 정책 자동 stream으로 정정) | 정성훈 |
