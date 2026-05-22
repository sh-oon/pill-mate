---
template: design
version: 1.2
feature: past-dose-edit
date: 2026-05-22
author: 정성훈
project: pill_mate
version: 1.0.0+4
---

# past-dose-edit Design Document

> **Summary**: 신규 등록/시각 추가 직후 조건부 `PastDosesBackfillSheet`를 노출해 오늘의 과거+활성+로그미존재 슬롯에 대해 일괄 `markTaken`을 가능하게 한다. UI/도메인 면적은 최소(신규 sheet 1 + repo 반환값 확장 + flow 분기 1).
>
> **Project**: pill_mate (Flutter)
> **Version**: 1.0.0+4
> **Author**: 정성훈
> **Date**: 2026-05-22
> **Status**: Draft
> **Planning Doc**: [past-dose-edit.plan.md](../../01-plan/features/past-dose-edit.plan.md)

> Pipeline References: N/A (이 변경은 schema/api/mockup 산출물 없음 — 클라이언트 UI/Repository 변경 only)

---

## 1. Overview

### 1.1 Design Goals

- 등록 흐름(`MedicationAddFlow._save`)에 backfill 단계를 **단일 진입점**으로 끼움 — 여러 분기에 흩어진 hook 회피
- `IntakeRepository`/`isScheduleActiveOn`/`combineDateAndTime` **기존 자산을 그대로 재사용** (신규 도메인 함수 0건)
- Repository 시그니처는 **named record**(`({int medicationId, List<int> scheduleIds})`)로 확장해 호출부 자가 문서화
- sheet는 dumb component — DB write는 caller(`_save`)가 소유 (기존 `BundleNotificationSheet` 컨벤션 그대로 따름)

### 1.2 Design Principles

- 단일 책임: sheet는 선택만, batch mark는 caller, 활성 판정은 `isScheduleActiveOn`(기존 헬퍼)
- YAGNI: 전체 선택/SnackBar 별도/skipped/edit-mode backfill 모두 v1 제외 (Plan §3.2/§3.3)
- 부분 성공 허용: 등록 트랜잭션이 이미 commit된 후 단계 — markTaken 일부 실패해도 등록은 유효
- 기존 통계 의도 보존: past-pending → 자동 `missed` 격상 금지 (Plan §3.3)

---

## 2. Architecture

### 2.1 Component Diagram

```
┌───────────────────────────────┐
│ medication_add_flow.dart      │
│   _save()                     │
│   _maybeBackfillTodayPast()   │◀───── 신규 분기 진입점
└──────────────┬────────────────┘
               │ uses
   ┌───────────┼─────────────────────────────────┐
   ▼           ▼                                 ▼
┌──────────┐  ┌─────────────────────────────┐  ┌───────────────────────────┐
│ Tracked  │  │ IntakeRepository            │  │ PastDosesBackfillSheet    │
│ Medi...  │  │  - mark/markTaken (기존)    │  │ (NEW)                     │
│ Reposi.. │  │  - logsAt(sids, day) (NEW)  │  │  static show() ───▶ Set?  │
│  insert/ │  └─────────────────────────────┘  └───────────────────────────┘
│  update  │
│  → ids   │  ┌─────────────────────────────┐
└──────────┘  │ isScheduleActiveOn          │
              │ combineDateAndTime          │
              │ (intake_repository.dart      │
              │  기존 free function)         │
              └─────────────────────────────┘
```

### 2.2 Data Flow

```
[User] "등록 완료" tap
       │
       ▼
[_save] catalog resolve → duplicate check
       │
       ├── duplicate yes ──► confirm dialog
       │                        │
       │                        ▼
       │              updateWithSchedules(existing.id, mergedDraft)
       │                        │ returns List<int> scheduleIds
       └── duplicate no  ──► insertWithSchedules(draft)
                                │ returns ({medId, scheduleIds})
                                ▼
                       _maybeBackfillTodayPast(medId, scheduleIds, draft, displayName)
                                │
                                ▼
                  ┌────────────────────────────────┐
                  │ 1) schedules query by ids       │
                  │ 2) intake_logs query (day window)│
                  │ 3) filter:                      │
                  │    isScheduleActiveOn(today)    │
                  │  & scheduledAt < now            │
                  │  & no IntakeLog row at slot     │
                  └────────────────────────────────┘
                                │
                       slots: List<PastDoseSlot>
                                │
                                ▼ (empty) → return
                            non-empty
                                │
                                ▼
                  PastDosesBackfillSheet.show(slots, medName)
                                │
                              Set<int>? (null/empty = skip)
                                │
                                ▼
                  for selected → repo.markTaken(...)
                                │
                                ▼
                  invalidate providers + SnackBar + pop  ← 기존 flow와 동일
```

### 2.3 Dependencies

| Component | Depends On | Purpose |
|-----------|-----------|---------|
| `medication_add_flow.dart` | `TrackedMedicationRepository`, `IntakeRepository`, `PastDosesBackfillSheet`, `isScheduleActiveOn`, `combineDateAndTime` | flow 오케스트레이션 |
| `PastDosesBackfillSheet` | `AppColors`, `AppButton` (기존) | UI만 |
| `TrackedMedicationRepository.insertWithSchedules` | Drift `app_database` | scheduleIds 수집을 위한 single-row insert + returning id |
| `IntakeRepository` (NEW method `logsAt`) | Drift `app_database` | day window IntakeLog 조회 |

---

## 3. Data Model

> DB 스키마 변경 없음. presentation/data 레이어에 도메인 타입 1개 신규.

### 3.1 신규 타입: `PastDoseSlot` (presentation-local)

```dart
// lib/features/medication/presentation/add/past_dose_slot.dart  (NEW)

class PastDoseSlot {
  const PastDoseSlot({
    required this.medicationId,
    required this.scheduleId,
    required this.timeOfDay,
    required this.scheduledAt,
  });

  final int medicationId;
  final int scheduleId;
  final String timeOfDay;       // "HH:mm" — sheet UI 표시용
  final DateTime scheduledAt;   // markTaken 호출에 사용
}
```

> 한 sheet에서 항상 동일 medication을 다루므로 `medName`은 sheet 인자(공통)로 분리하고 `PastDoseSlot`에는 넣지 않음.

### 3.2 Repository 반환값 시그니처 변경

#### `insertWithSchedules`

```dart
// Before
Future<int> insertWithSchedules(TrackedMedicationDraft draft);

// After
Future<({int medicationId, List<int> scheduleIds})> insertWithSchedules(
  TrackedMedicationDraft draft,
);
```

#### `updateWithSchedules`

```dart
// Before
Future<void> updateWithSchedules(int id, TrackedMedicationDraft draft);

// After — 새로 insert된 schedule row id 리스트 반환
Future<List<int>> updateWithSchedules(int id, TrackedMedicationDraft draft);
```

### 3.3 신규 메서드: `IntakeRepository.logsAt`

```dart
/// 주어진 [scheduleIds]와 정확한 [scheduledAt] 집합에 매칭되는 기존 IntakeLog 조회.
/// backfill 후보 필터링용 (이미 로그된 슬롯은 노출 제외).
///
/// 구현: scheduledAt이 [day, day+1) 범위인 모든 로그를 가져온 뒤 caller가
///       (scheduleId, scheduledAt) 쌍으로 매칭. day window 좁은 query 1회로 끝.
Future<List<IntakeLog>> logsAt({
  required List<int> scheduleIds,
  required DateTime day,
});
```

```dart
// 구현 sketch
Future<List<IntakeLog>> logsAt({
  required List<int> scheduleIds,
  required DateTime day,
}) {
  if (scheduleIds.isEmpty) return Future.value(const []);
  final start = DateTime(day.year, day.month, day.day);
  final end = start.add(const Duration(days: 1));
  return (_db.select(_db.intakeLogs)
        ..where((l) =>
            l.scheduleId.isIn(scheduleIds) &
            l.scheduledAt.isBetweenValues(start, end)))
      .get();
}
```

---

## 4. API Specification

N/A — 본 변경은 외부 API/네트워크 호출이 없는 클라이언트(Flutter) 내부 변경.

---

## 5. UI/UX Design

### 5.1 Sheet 레이아웃

```
┌───────────────────────────────────────────────┐
│              ▬▬ (drag handle, 36×4)           │
│                                               │
│  오늘 이미 챙기셨나요?               [×]      │  ← header (close button)
│  {medName} 등록 전 시각이 있어요              │  ← subtitle (gray, body2)
│                                               │
│  ┌─────────────────────────────────────────┐ │
│  │ ☐  08:00     {medName}        1정       │ │  ← row (tap → toggle)
│  ├─────────────────────────────────────────┤ │
│  │ ☐  13:00     {medName}        1정       │ │
│  └─────────────────────────────────────────┘ │
│                                               │
│  ┌──────────────┐  ┌──────────────────────┐  │
│  │  건너뛰기    │  │    기록할게요         │  │  ← action row
│  │  (tint)      │  │    (primary, full)    │  │
│  └──────────────┘  └──────────────────────┘  │
└───────────────────────────────────────────────┘
```

규격:
- Container padding `EdgeInsets.fromLTRB(22, 18, 22, 24 + viewInsets.bottom)` (기존 `EditRecordSheet` 동일)
- 배경 `AppColors.surface`, 상단 라운드 24
- handle bar `AppColors.borderHairline`, 36×4, radius 2
- header: title `text-style heading` (기존 톤), close icon button 우측
- row: `InkWell` tap-toggle, 좌측 체크박스, 시각 monospace tabular, 약명, 우측 수량 라벨. divider 1px `AppColors.border`
- 버튼 row: `AppButton` × 2 (variant: tint / primary), `fullWidth` 동일 비율
- 분량 표시 형식은 `computeDosesForDay`의 `quantityOf` 정책 그대로 (caller 측에서 미리 계산해 sheet에 string으로 전달)

### 5.2 User Flow

```
Step3 "등록 완료" tap
  └─ 저장 진행 (loading spinner: 기존 _saving 상태 그대로)
      └─ 저장 성공
          ├─ backfill 후보 없음 → 기존 SnackBar "등록되었어요" + pop  (no change)
          └─ backfill 후보 있음 → BottomSheet open
              ├─ 사용자가 슬롯 0개 선택 후 "기록할게요" → mark 0회 → SnackBar + pop
              ├─ 사용자가 N개 선택 후 "기록할게요" → mark N회 → SnackBar + pop
              ├─ 사용자가 "건너뛰기" → mark 0회 → SnackBar + pop
              └─ 사용자가 외부 dismiss (barrier tap/swipe) → mark 0회 → SnackBar + pop
```

### 5.3 Component List

| Component | Location | Responsibility |
|-----------|----------|----------------|
| `PastDosesBackfillSheet` | `lib/core/widgets/sheets/past_doses_backfill_sheet.dart` (NEW) | sheet UI · 체크 상태 관리 · `Set<int>?` 반환 |
| `PastDoseSlot` | `lib/features/medication/presentation/add/past_dose_slot.dart` (NEW) | 도메인 값 객체 |
| `_maybeBackfillTodayPast` | `lib/features/medication/presentation/add/medication_add_flow.dart` (private method 추가) | 후보 계산 + sheet 호출 + batch mark 오케스트레이션 |

### 5.4 Sheet API

```dart
class PastDosesBackfillSheet extends StatefulWidget {
  // ...
  /// [slots]: 노출할 과거 슬롯들 (caller가 이미 필터링 완료)
  /// [medName]: header 부제목용 약 이름
  /// [quantityLabelOf]: slot 별 우측 수량 라벨 (caller가 계산)
  ///
  /// 반환:
  ///   - Set<int>: 선택된 slot 인덱스 (`slots[i]`의 i)
  ///   - null: dismiss/외부 닫힘 (= skip)
  ///   - 빈 Set: "건너뛰기" or 아무것도 선택 안 하고 "기록할게요" (= skip 동치)
  static Future<Set<int>?> show(
    BuildContext context, {
    required List<PastDoseSlot> slots,
    required String medName,
    required String Function(PastDoseSlot) quantityLabelOf,
  });
}
```

> 호출자는 `null`과 빈 Set을 동등 처리하면 됨(어차피 mark 호출 0회).

---

## 6. Error Handling

| Case | Behavior |
|------|----------|
| `insertWithSchedules`/`updateWithSchedules` 실패 | 기존 try/catch에서 "저장 실패: $e" SnackBar (no change). backfill 단계는 진입하지 않음. |
| `_maybeBackfillTodayPast` 내부 query 실패 | catch → 콘솔 로깅 + backfill skip (등록 자체는 성공으로 처리, 기존 SnackBar/pop로 진행). 사용자에게 별도 알림 안 함. |
| `markTaken` 일부 실패 | catch each in loop → 콘솔 로깅 후 다음 slot 진행. SnackBar는 기존 그대로 ("등록되었어요"). v2에서 실패한 slot 개수를 SnackBar에 추가 노출 검토 (현재 YAGNI). |
| context unmounted (사용자 빠른 pop) | `if (!mounted) return;` 가드 (기존 `_save`와 동일 패턴) |
| 시각이 정확히 `DateTime.now()`와 일치 (경계) | `isBefore(now)` → false → 후보 제외. 사용자에게는 "1초 차이로 미노출" 정도의 자연스러운 경계 동작. |
| 자정 직전 등록 후 sheet 표시 중 자정 넘어감 | 후보 list는 sheet open 시점에 고정. 자정 넘은 후 mark되어도 `scheduledAt`은 어제 날짜 — IntakeLog row가 어제 날짜로 정확히 기록되어 의도 부합. |
| sheet 표시 중 backgrounded → 복귀 | `showModalBottomSheet` 기본 동작 — 그대로 유지. |

---

## 7. Security Considerations

N/A — 로컬 DB(Drift) 단일, 네트워크/암호화/인증 관련 변경 없음. 사용자 본인 데이터만 다룸.

---

## 8. Test Plan

### 8.1 Test Scope

| Type | Target | Tool |
|------|--------|------|
| Manual scenario | `medication_add_flow` 등록 경로 + backfill sheet | 실기기 또는 emulator |
| Static analysis | 전체 변경 영역 | `flutter analyze` (CI/local) |
| Build smoke | 빌드 깨짐 여부 | `flutter build apk --debug` |

> Unit test는 본 변경에서는 추가하지 않음 — 프로젝트 현행 테스트 부재. 후속 ENH로 분리 가능.

### 8.2 Test Cases (Manual)

핵심 시나리오 (Plan §1.3과 동기화):

- [ ] **TC-01 신규 등록 + 오늘 다수 과거 시각**: 오늘 14:00에 신규 등록(daily, 08:00/13:00/20:00) → sheet에 08:00·13:00 두 행 노출, 20:00 미노출
- [ ] **TC-02 두 슬롯 모두 체크 → 기록**: TC-01에서 두 행 체크 → "기록할게요" → home 진입 시 08:00·13:00 모두 `taken` 배지
- [ ] **TC-03 "건너뛰기"**: TC-01에서 "건너뛰기" → 기존 SnackBar "등록되었어요" + pop, home의 08:00·13:00은 `pending` (기존 동작)
- [ ] **TC-04 dismiss**: TC-01에서 barrier tap/swipe-down → "건너뛰기"와 동일 결과
- [ ] **TC-05 후보 없음**: 오늘 07:00에 등록 + 시각 08:00/13:00 → sheet 미노출, 기존 SnackBar + pop
- [ ] **TC-06 weekly 비활성 요일**: weekly 약, 오늘이 mask에 없는 요일 → sheet 미노출 (과거 시각 있어도)
- [ ] **TC-07 weekly 활성 요일**: weekly 약, 오늘이 mask에 있는 요일, 시각 08:00/14:00, 오늘 15:00 등록 → sheet에 08:00·14:00 두 행
- [ ] **TC-08 interval 등록일**: interval=2 약, 오늘 등록 → diff=0%2=0 → 활성, 과거 시각 후보 노출
- [ ] **TC-09 catalog 중복 "시각 추가"**: 같은 catalog 이미 등록(시각 08:00), 시각 14:00 추가 시도, 오늘 16:00 → confirm dialog "시각 추가" → sheet에 14:00만 노출 (08:00은 이미 today log/missed/taken 가능성 → IntakeLog 부재 가드)
- [ ] **TC-10 `_isEdit=true`**: 약 상세 → 편집 → sheet 미노출 (early-return)
- [ ] **TC-11 backfill skip 후 home 인터랙션**: TC-03 후 home의 08:00 슬롯 → 기존 동작(`highlight = 첫 미래 pending`)대로 take 버튼 미노출 → 변경 없음 확인
- [ ] **TC-12 part failure**: `markTaken` 강제 실패(예: 디버그 코드 inject) → SnackBar는 등록 성공으로 표시, 콘솔에 실패 로그 — 후처리 회귀 없음 확인

### 8.3 회귀 체크

- [ ] catalog-phase-2c "시각 추가" 분기 흐름 정상 (confirm dialog → 저장 → home invalidate)
- [ ] `_notif.syncSchedulesFor` 호출이 등록 + 각 markTaken에서 발생해도 알림 큐 정합 (멱등 확인)
- [ ] `flutter analyze` clean
- [ ] 기존 `insertWithSchedules` / `updateWithSchedules` caller 모두 갱신 (signature 변경 영향)

---

## 9. Clean Architecture

### 9.1 Layer Structure (Flutter — pill_mate 실제 구조)

| Layer | Responsibility | Location |
|-------|---------------|----------|
| **Presentation** | Screens, widgets, sheets, flow state | `lib/features/*/presentation/`, `lib/core/widgets/` |
| **Data/Repository** | DB/Drift 접근, 도메인 객체 정의 | `lib/features/*/data/`, `lib/core/database/` |
| **Core / Cross-cutting** | 알림, 권한, 라우터, 테마 | `lib/core/` |

### 9.2 본 feature의 Layer 할당

| Component | Layer | Location |
|-----------|-------|----------|
| `PastDosesBackfillSheet` | Presentation (cross-cutting widget) | `lib/core/widgets/sheets/past_doses_backfill_sheet.dart` |
| `PastDoseSlot` | Presentation-local value object | `lib/features/medication/presentation/add/past_dose_slot.dart` |
| `_maybeBackfillTodayPast` | Presentation (private method on `_MedicationAddFlowState`) | `lib/features/medication/presentation/add/medication_add_flow.dart` |
| `insertWithSchedules`/`updateWithSchedules` signature 확장 | Data | `lib/features/medication/data/medication_repository.dart` |
| `IntakeRepository.logsAt` | Data | `lib/features/medication/data/intake_repository.dart` |

### 9.3 의존 방향

```
PastDosesBackfillSheet (Presentation, 순수 UI)
            ▲ (호출/결과)
medication_add_flow._save → _maybeBackfillTodayPast (Presentation)
            │
            ▼ (data layer 호출)
TrackedMedicationRepository · IntakeRepository (Data)
            │
            ▼
AppDatabase / Drift (Infrastructure)
```

Sheet → Data 직접 호출 없음. Data layer의 신규 메서드(`logsAt`)는 presentation에서만 사용.

---

## 10. Coding Convention Reference

### 10.1 Project Conventions (pill_mate)

| Target | Rule | Example |
|--------|------|---------|
| Dart 파일명 | snake_case.dart | `past_doses_backfill_sheet.dart` |
| Widget class | PascalCase | `PastDosesBackfillSheet` |
| Static factory | `show(BuildContext, {...})` 패턴 | `EditRecordSheet.show`, `BundleNotificationSheet.show` |
| Sheet 위치 | `lib/core/widgets/sheets/` | 기존 `edit_record_sheet.dart`, `bundle_notification_sheet.dart` 동일 |
| 색상 토큰 | `AppColors.*` 만 사용, hex literal 금지 | `AppColors.surface`, `AppColors.primary` |
| 버튼 | `AppButton(variant: AppButtonVariant.{primary|primaryTint}, fullWidth: true)` | 기존 sheet 패턴 |
| 한국어 주석 | 코드 의도/edge case 한국어 OK (기존 코드베이스 톤) | `intake_repository.dart:217-219` 톤 따름 |

> 글로벌 CLAUDE.md의 React/cva/cn/`@surromind/icons` 규칙은 본 프로젝트에 비적용(Flutter).

### 10.2 본 feature의 Conventions

| Item | Convention Applied |
|------|-------------------|
| Sheet 신규 | 기존 sheet 컨벤션(handle bar / header / body / action row) 그대로 |
| Repository 반환 | Dart record (named) — 가독성/자가 문서화 |
| `Future<List<int>>` 반환 | dedup 후 insert 순서대로 — 결정적 순서 보장 |
| 한국어 주석 | sheet/메서드 헤더 주석 한국어 (의도/edge case) |

---

## 11. Implementation Guide

### 11.1 File Structure (변경 후)

```
lib/
├── core/widgets/sheets/
│   ├── bundle_notification_sheet.dart       (existing)
│   ├── edit_record_sheet.dart               (existing)
│   └── past_doses_backfill_sheet.dart       (NEW)
└── features/medication/
    ├── data/
    │   ├── intake_repository.dart           (modify — add logsAt)
    │   └── medication_repository.dart       (modify — signature)
    └── presentation/add/
        ├── medication_add_flow.dart         (modify — _maybeBackfillTodayPast)
        └── past_dose_slot.dart              (NEW)
```

### 11.2 Implementation Order

1. [ ] **Step 1 — Data signature**: `insertWithSchedules` 반환 변경 `int` → `({int medicationId, List<int> scheduleIds})`. insert loop에서 schedule row id 수집 (Drift `into(table).insert(...)`의 반환값 = inserted row id). 컴파일 에러 발생하는 caller 위치 grep으로 확인 (현재 `medication_add_flow.dart` 1곳 예상)
2. [ ] **Step 2 — updateWithSchedules signature**: 동일 패턴으로 `Future<void>` → `Future<List<int>>`. 새로 insert된 schedule row id만 수집(`delete` 후 re-insert이므로 모든 id가 신규)
3. [ ] **Step 3 — `IntakeRepository.logsAt`**: §3.3 구현. 빈 입력 short-circuit
4. [ ] **Step 4 — `PastDoseSlot`**: §3.1 정의
5. [ ] **Step 5 — `PastDosesBackfillSheet`**: §5.1/§5.4. `StatefulWidget` + `Set<int>` 상태. `showModalBottomSheet<Set<int>>` 사용(기존 `EditRecordSheet` 패턴). `_DoseRow` 비슷한 row 위젯은 내부 private class
6. [ ] **Step 6 — `_maybeBackfillTodayPast`**: §2.2의 절차 그대로 구현. 호출 위치는 `_save()` 내부 — 신규 insert/시각 추가 update 분기 모두 통과 후, 기존 `invalidate` 전에 호출. `_isEdit=true` 분기는 early-return
7. [ ] **Step 7 — `_save()` 분기 연결**: insert/update 결과 변수에서 `scheduleIds`를 받아 backfill 호출. SnackBar/pop은 backfill 완료 후 동일 위치에서 발생
8. [ ] **Step 8 — Manual TC**: §8.2 TC-01~TC-12 수행
9. [ ] **Step 9 — `flutter analyze`**: clean 확인

### 11.3 Pseudocode — `_maybeBackfillTodayPast`

```dart
Future<void> _maybeBackfillTodayPast({
  required int medicationId,
  required List<int> scheduleIds,
  required TrackedMedicationDraft draft,
  required String medName,
  required String Function(PastDoseSlot) quantityLabelOf,
}) async {
  if (scheduleIds.isEmpty) return;

  final db = ref.read(appDatabaseProvider);
  final intakeRepo = ref.read(intakeRepositoryProvider);

  // 1) schedule rows 재조회 (startDate/repeatKind/mask/interval/timeOfDay 필요)
  final schedules = await (db.select(db.schedules)
        ..where((s) => s.id.isIn(scheduleIds)))
      .get();

  final today = DateTime.now();
  final dayKey = DateTime(today.year, today.month, today.day);
  final now = DateTime.now();

  // 2) 후보 1차 필터 (DB 조회 전)
  final candidates = <PastDoseSlot>[];
  for (final s in schedules) {
    final scheduledAt = combineDateAndTime(dayKey, s.timeOfDay);
    if (!scheduledAt.isBefore(now)) continue;
    if (!isScheduleActiveOn(s, dayKey)) continue;
    candidates.add(PastDoseSlot(
      medicationId: medicationId,
      scheduleId: s.id,
      timeOfDay: s.timeOfDay,
      scheduledAt: scheduledAt,
    ));
  }
  if (candidates.isEmpty) return;

  // 3) IntakeLog 부재 가드
  final existingLogs = await intakeRepo.logsAt(
    scheduleIds: candidates.map((c) => c.scheduleId).toList(),
    day: dayKey,
  );
  final loggedKeys = existingLogs
      .map((l) => '${l.scheduleId}|${l.scheduledAt.toIso8601String()}')
      .toSet();
  final slots = candidates
      .where((c) =>
          !loggedKeys.contains('${c.scheduleId}|${c.scheduledAt.toIso8601String()}'))
      .toList();
  if (slots.isEmpty) return;

  // 4) sheet 호출
  if (!mounted) return;
  final selected = await PastDosesBackfillSheet.show(
    context,
    slots: slots,
    medName: medName,
    quantityLabelOf: quantityLabelOf,
  );
  if (selected == null || selected.isEmpty) return;

  // 5) batch mark (부분 성공 허용)
  for (final i in selected) {
    final s = slots[i];
    try {
      await intakeRepo.markTaken(
        medicationId: s.medicationId,
        scheduleId: s.scheduleId,
        scheduledAt: s.scheduledAt,
      );
    } catch (e, st) {
      // 등록 자체는 이미 성공 — log만 남기고 다음 슬롯 진행
      // ignore: avoid_print
      print('past-dose-edit markTaken failed for $s: $e\n$st');
    }
  }
}
```

### 11.4 `_save()` 통합 위치 (diff intent)

```
... (existing) repo.insertWithSchedules(draft);  // → 이제 ({medId, scheduleIds})
                                                  //   또는 updateWithSchedules → List<int>
+ if (!_isEdit) {
+   await _maybeBackfillTodayPast(
+     medicationId: <medId from insert or existing.id from update branch>,
+     scheduleIds: <List<int>>,
+     draft: draft,
+     medName: <Step2 입력 또는 catalog.name 결정 후 값>,
+     quantityLabelOf: (slot) => _formatQuantity(draft),  // draft 기반 정적 계산
+   );
+ }
ref.invalidate(todayLogsProvider);
ref.invalidate(trackedMedicationsStreamProvider);
... (existing SnackBar + pop)
```

> `quantityLabelOf`는 draft만으로 동일 라벨이 나오므로 클로저로 캡쳐. 슬롯별로 다른 분량을 표시할 가능성은 v1에서 없음(YAGNI).

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 0.1 | 2026-05-22 | Initial draft | 정성훈 |
