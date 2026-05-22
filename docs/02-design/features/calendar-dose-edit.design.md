---
template: design
version: 1.2
feature: calendar-dose-edit
date: 2026-05-22
author: 정성훈
project: pill_mate
appVersion: 3.0.0+7
---

# calendar-dose-edit Design Document

> **Summary**: Calendar `_RecordCard`를 tap-aware로 만들고, 기존 `EditRecordSheet`를 양방향 toggle(taken↔missed) 지원으로 확장한다. Home `_openEditSheet`도 새 props로 정합화하며, `computeDosesForDay`는 과거 날짜의 hasLog=false 활성 슬롯을 read-only로 `missed` 계산한다. 변경 면적은 sheet 1개 확장 + Calendar 1메서드 신규 + Home 1메서드 정합 + Repository(presentation-only 계산) 1군데 수정.
>
> **Project**: pill_mate (Flutter)
> **Version**: 3.0.0+7
> **Author**: 정성훈
> **Date**: 2026-05-22
> **Status**: Draft
> **Planning Doc**: [calendar-dose-edit.plan.md](../../01-plan/features/calendar-dose-edit.plan.md)

> Pipeline References: N/A (이 변경은 schema/api/mockup 산출물 없음 — 클라이언트 UI/계산 변경 only)

---

## 1. Overview

### 1.1 Design Goals

- 사후 편집을 **단일 sheet 위젯**(`EditRecordSheet`)에 집약 — Calendar/Home 공유, 코드 중복 0
- props 추가는 **모두 default 가능** — 기존 Home 호출 무손상 (점진적 마이그레이션)
- `IntakeRepository.markTaken`/`markMissed` upsert를 그대로 활용 — 신규 메서드 0
- 과거 자동 missed는 **계산만**(read-only) — log row 미생성, undo 자유
- 미래 dose 가드는 **진입점에서** 한 번에 적용 — sheet open 자체를 차단

### 1.2 Design Principles

- **단일 책임**: sheet는 사용자 선택을, repo는 upsert를, screen은 invalidate/feedback을
- **YAGNI**: skipped/메모/일괄/Undo/날짜 라벨 풀 정밀화 모두 v1 제외 (Plan §3.2)
- **호환 우선**: `EditRecordSheet` 기존 호출부(Home) 컴파일 무손상 + 새 props 마이그레이션은 별도 step
- **정확성 회복**: 과거 pending → missed 격상은 보고서 수치 정합 목적 — 의도된 변화이므로 release note 기록
- **다중 surface 일관성**: invalidate set은 `(day, year/month)` 한 쌍에서 파생 — 호출 컨텍스트별 helper 없이 명시적 호출

---

## 2. Architecture

### 2.1 Component Diagram

```
┌─────────────────────────────────────────┐
│ calendar_screen.dart                    │
│  _RecordCard (tap-aware: InkWell)       │
│            │                            │
│            ▼                            │
│  _openEditSheet(dose)  ◀── 신규 메서드  │
└──────────────┬──────────────────────────┘
               │
               │ shares ──────────────────────────┐
               ▼                                  │
┌──────────────────────────────────┐              │
│ EditRecordSheet (EXTEND)         │              │
│  enum + { markMissed }           │              │
│  props + { allowMissed,          │              │
│            currentStatus,        │              │
│            dateLabel }           │              │
│  static show(...) → choice       │              │
└──────────────┬───────────────────┘              │
               │                                  │
               ▼                                  │
┌──────────────────────────────────┐              │
│ IntakeRepository (EXISTING)      │              │
│  markTaken / markMissed = upsert │              │
│  (no new methods)                │              │
└──────────────────────────────────┘              │
                                                  │
┌─────────────────────────────────────────┐       │
│ home_screen.dart                        │       │
│  _openEditSheet (정합화 - props 사용)   │───────┘
│  (markMissed 처리 분기 추가)            │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ intake_repository.dart                  │
│  computeDosesForDay (MODIFY)            │
│    + 과거 날짜 missed 계산 (read-only)  │
└─────────────────────────────────────────┘
```

### 2.2 Data Flow

```
[User] Calendar 그날 카드 tap
        │
        ▼
[_openEditSheet(dose)]
        │
        ├── dose.scheduledAt > DateTime.now() ──► SnackBar("아직 예정된 복용입니다") + return
        │
        ▼
[EditRecordSheet.show(
    medName, category, time,
    dateLabel: _relativeLabel(dose.scheduledAt),
    currentStatus: dose.status,
    allowMissed: true,
 )]
        │
        ▼
   choice ∈ { keep, markTaken, markMissed, null }
        │
        ├── keep / null   → return (no-op)
        ├── markTaken     → repo.markTaken(medId, schedId, scheduledAt)
        └── markMissed    → repo.markMissed(medId, schedId, scheduledAt)
                                        │
                                        ▼
                            intake_logs upsert (mark 내부)
                                        │
                                        ▼
                            notif cancel + sync (mark 내부)
        │
        ▼
[invalidate set]
   ref.invalidate(dayDosesProvider(_dateOnly(dose.scheduledAt)))
   ref.invalidate(monthMarksProvider((year, month)))
   ref.invalidate(todayCountsProvider)       ← Home summary 동기화
   ref.invalidate(nextDoseProvider)          ← Home next 동기화
   reports family invalidate (호출 컨텍스트에 따라)
        │
        ▼
[SnackBar 분기 메시지]
   markTaken  → "'이미 복용'으로 수정했어요"
   markMissed → "'놓침'으로 수정했어요"
```

### 2.3 Dependencies

| Component | Depends On | Purpose |
|-----------|------------|---------|
| `calendar_screen.dart` (`_CalendarScreenState`) | `EditRecordSheet`, `IntakeRepository`, `intakeRepositoryProvider`, `dayDosesProvider`, `monthMarksProvider`, family providers | tap → sheet → mark → invalidate → feedback |
| `home_screen.dart` (`_HomeScreenState`) | `EditRecordSheet`, `IntakeRepository`, today/next family | 새 props 정합화 + markMissed 분기 |
| `EditRecordSheet` | `AppColors`, `AppButton`, `IntakeStatus` (database types) | UI + 액션 row 분기 |
| `computeDosesForDay` (free function in `intake_repository.dart`) | `Schedule`, `IntakeLog`, `isScheduleActiveOn` | 과거 missed 계산 추가 (read-only) |

---

## 3. Data Model

> DB 스키마 변경 없음. enum 1항목 + sheet props 3개 + 계산 분기 1개 추가.

### 3.1 `EditRecordChoice` enum 확장

```dart
// lib/core/widgets/sheets/edit_record_sheet.dart

enum EditRecordChoice {
  keep,
  markTaken,
  markMissed,   // ← NEW
}
```

### 3.2 `EditRecordSheet` props 확장

```dart
// Before
static Future<EditRecordChoice?> show(
  BuildContext context, {
  required String medName,
  required String category,
  required String time,
  bool yesterday = false,
})

// After
static Future<EditRecordChoice?> show(
  BuildContext context, {
  required String medName,
  required String category,
  required String time,
  @Deprecated('Use dateLabel') bool yesterday = false,  // 호환 — default fallback
  String? dateLabel,            // 우선 표시 라벨 — null이면 yesterday→"어제"/"오늘"
  IntakeStatus? currentStatus,  // 액션 row 라벨 강조 분기에 사용
  bool allowMissed = false,     // true → "놓침으로 표시" 액션 노출
})
```

### 3.3 `_relativeLabel(DateTime scheduledAt) → String` (presentation helper)

```dart
// _CalendarScreenState · _HomeScreenState 양쪽에 동일 helper 또는 file-level private 함수
String _relativeLabel(DateTime scheduledAt) {
  final today = DateTime.now();
  final t = DateTime(today.year, today.month, today.day);
  final d = DateTime(scheduledAt.year, scheduledAt.month, scheduledAt.day);
  final delta = d.difference(t).inDays;
  if (delta == 0) return '오늘';
  if (delta == -1) return '어제';
  if (delta < -1) return '${-delta}일 전';
  return '${scheduledAt.month}월 ${scheduledAt.day}일'; // 미래(가드되지만 fallback)
}
```

> Calendar/Home에서 동일 형태 사용. 중복 회피 위해 `lib/core/utils/relative_date.dart` 신규 또는 `intake_repository.dart` 내 free function로 둘 수 있으나, v1은 **각 screen 파일에 private 함수**로 두고 중복 발견 시 별도 ENH(코드 8줄, 추출 비용 < 가치).

### 3.4 `computeDosesForDay` 과거 missed 계산 변경 (diff intent)

```dart
// intake_repository.dart:252-265 (현재)
final beforeStart = scheduledAt.isBefore(s.startDate);
final IntakeStatus status;
if (hasLog) {
  status = log.status;
} else if (isToday &&
    !beforeStart &&
    nowTime.isAfter(scheduledAt.add(const Duration(minutes: 5)))) {
  status = IntakeStatus.missed;
} else {
  status = IntakeStatus.pending;
}
```

```dart
// after
final beforeStart = scheduledAt.isBefore(s.startDate);
final isPastDay = _dateOnly(date).isBefore(_dateOnly(nowTime));   // ← NEW
final IntakeStatus status;
if (hasLog) {
  status = log.status;
} else if (beforeStart) {
  status = IntakeStatus.pending;                                  // 기존 의도 유지
} else if (isToday &&
    nowTime.isAfter(scheduledAt.add(const Duration(minutes: 5)))) {
  status = IntakeStatus.missed;
} else if (isPastDay) {
  status = IntakeStatus.missed;                                   // ← NEW: 과거날짜 자동 격상
} else {
  status = IntakeStatus.pending;
}
```

**불변 보장**:
- `beforeStart` 가드 우선 — 등록일 이전의 schedule 슬롯은 계속 pending (기존 통계 의도)
- log row 미생성 — 사용자가 toggle하면 비로소 log row가 생기고 그 status가 우선 (`if (hasLog)` 분기 먼저)
- isToday 분기 무영향 — 오늘 슬롯의 자동 missed 격상은 기존 5분 grace 그대로

---

## 4. API Specification

N/A — 외부 API/네트워크 없음. 클라이언트(Flutter) 내부 변경만.

---

## 5. UI/UX Design

### 5.1 `EditRecordSheet` 액션 row 분기 표

| `currentStatus` | `allowMissed` | 좌측 버튼 | 우측 버튼 (강조) | 비고 |
|---|---|---|---|---|
| `null`/missed/pending | false (Home 현행) | "그대로 둘게요" → `keep` | "이미 복용했어요" → `markTaken` | 기존 호출 시그니처 100% 동일 |
| `pending` | true | "놓침으로 표시" → `markMissed` | "이미 복용했어요" → `markTaken` | Calendar 미래-아닌 미기록 dose |
| `missed` | true | "그대로 둘게요" → `keep` | "이미 복용했어요" → `markTaken` | "이미 missed"라 missed 다시 누를 의미 적음 |
| `taken` | true | "놓침으로 수정" → `markMissed` | "그대로 둘게요" → `keep` | 잘못 taken 표시한 케이스 복구 |
| `skipped` | true | "놓침으로 표시" → `markMissed` | "이미 복용했어요" → `markTaken` | skipped는 IntakeStatus enum에는 있지만 UX 표시 동일 |

> 정책: `allowMissed=true` 분기는 currentStatus에 따라 라벨/강조를 바꾸되 enum return은 그대로. screen에서 enum으로 분기.

### 5.2 Sheet 레이아웃 변경 (mockup)

```
┌───────────────────────────────────────────────┐
│              ▬▬ (drag handle)                 │
│                                               │
│  기록 수정                                [×] │
│  {medName}을(를) {dateLabel ?? "오늘"} 드셨나요?
│                                               │
│  ┌─────────────────────────────────────────┐ │
│  │  [💊] {medName}  {category chip}        │ │
│  │       {time} · {currentStatus 라벨}      │ │
│  └─────────────────────────────────────────┘ │
│                                               │
│  ┌────────────────────┐ ┌──────────────────┐  │
│  │  좌측 버튼          │ │  우측 버튼 (강조) │  │
│  │  (variant: tint)    │ │  (variant: primary)│
│  └────────────────────┘ └──────────────────┘  │
└───────────────────────────────────────────────┘
```

규격:
- 기존 sheet 규격 그대로(padding/handle/round/AppColors)
- `_MedInfoCard` 내 `'$time · 놓침으로 표시됨'` 하드코딩 제거 → `currentStatus`에 따라 "이미 복용", "예정", "놓침", "건너뜀" 분기
- 액션 row는 항상 2버튼(현행 그대로). 라벨/`variant`/return enum만 분기

### 5.3 User Flow

```
Calendar 그날 카드 tap
  ├── 미래 dose ──► SnackBar "아직 예정된 복용입니다" + 종료
  └── 과거/오늘 dose ──► EditRecordSheet
        ├── keep / dismiss ──► no-op
        ├── markTaken       ──► repo.markTaken → invalidate → SnackBar "'이미 복용'으로 수정했어요"
        └── markMissed      ──► repo.markMissed → invalidate → SnackBar "'놓침'으로 수정했어요"

Home 그날 카드(missed) tap (기존 _openEditSheet)
  └── 동일 sheet, allowMissed=true, dateLabel=동적
        (정합화 후 양방향 toggle 가능)
```

### 5.4 Component List

| Component | Location | Responsibility | 변경 |
|-----------|----------|----------------|-----|
| `EditRecordSheet` | `lib/core/widgets/sheets/edit_record_sheet.dart` | sheet UI + 액션 row 분기 | **수정** (props 3 + enum 1 + 본문/버튼 분기) |
| `_RecordCard` | `lib/features/calendar/presentation/calendar_screen.dart` | 그날 기록 카드 | **수정** (InkWell wrap, `onTap` 콜백 받음) |
| `_CalendarScreenState._openEditSheet` | 동 파일 | tap handler + sheet 호출 + mark + invalidate + SnackBar | **신규** |
| `_relativeLabel` | calendar_screen.dart, home_screen.dart (각자) | 날짜 라벨 계산 | **신규** (private function) |
| `_HomeScreenState._openEditSheet` | `lib/features/home/presentation/home_screen.dart` | 정합화 + markMissed 분기 | **수정** |
| `computeDosesForDay` | `lib/features/medication/data/intake_repository.dart` | 과거 missed 계산 | **수정** |

### 5.5 Calendar `_RecordCard` tap 통합

```dart
// before
class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.record});
  final DoseInstance record;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(/* ... */),
      child: Row(/* ... */),
    );
  }
}

// after
class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.record, required this.onTap});
  final DoseInstance record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            // background는 Material로 옮겨 ripple 위로 안 흐리게
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(/* ... 기존 동일 ... */),
        ),
      ),
    );
  }
}
```

> 호출부(`TimelineRow`):
> ```dart
> child: _RecordCard(
>   record: r,
>   onTap: () => _openEditSheet(r),
> ),
> ```

---

## 6. Error Handling

| Case | Behavior |
|------|----------|
| 미래 dose tap | sheet 미노출 + SnackBar "아직 예정된 복용입니다" (variant: info) |
| `markTaken`/`markMissed` 실패 | catch → SnackBar "변경 실패: $e" (variant: error). invalidate는 호출하지 않음(상태 변동 없음) |
| context unmounted (사용자 빠른 pop) | `if (!context.mounted) return;` 가드 — mark 완료 후 SnackBar/invalidate 모두 가드 |
| sheet 표시 중 device 회전 | `showModalBottomSheet` 기본 동작 — 상태(Stateless) 무영향 |
| 동일 dose 빠른 연타 toggle | upsert이므로 마지막 mark 승리. UI는 마지막 invalidate에 의해 최종 상태 노출. race는 무해 |
| `computeDosesForDay` 과거 missed 격상이 weekly/monthly report 수치 한 번에 크게 변경 | 의도된 정합성 회복. 사용자 노출은 release note에 기록 (Plan §7 Risks) |
| `_dateOnly(date).isBefore(_dateOnly(nowTime))` 경계 (자정 직전) | nowTime 캡처 시점 기준 — 자정 넘은 직후 호출 시 어제로 계산. 짧은 race window 무해 |

---

## 7. Security Considerations

N/A — 로컬 Drift DB만 사용. 네트워크/암호화/인증 무관.

---

## 8. Test Plan

### 8.1 Test Scope

| Type | Target | Tool |
|------|--------|------|
| Static analysis | 전체 변경 영역 | `flutter analyze` |
| Manual scenario | Calendar tap + sheet + invalidate, Home 정합화, 과거 missed 계산 | 실기기/emulator |
| Build smoke | 빌드 깨짐 여부 | `flutter build apk --debug` |

> Unit test는 프로젝트 현행 무함 — 본 변경에서 추가하지 않음. 후속 ENH로 분리 가능.

### 8.2 Test Cases (Manual)

핵심 시나리오 (Plan §1.3과 동기화):

- [ ] **TC-01 Calendar 어제 pending → taken**: Calendar에서 어제 날짜로 이동 → pending 카드 tap → sheet에 "어제" 라벨 + 2버튼(놓침/이미 복용) → "이미 복용했어요" → 카드 status `taken` + dot 완료색
- [ ] **TC-02 Calendar 어제 taken → missed**: TC-01 직후 같은 카드 tap → sheet 라벨 "놓침으로 수정" 강조 → tap → 카드 `missed` + dot 변경
- [ ] **TC-03 Calendar 어제 missed → taken**: TC-02 직후 카드 tap → "이미 복용했어요" → `taken` 복귀
- [ ] **TC-04 Calendar 오늘 pending → taken**: 오늘 날짜 pending 카드 tap → toggle 작동, today summary count 변경
- [ ] **TC-05 Calendar 미래 dose 가드**: 오늘 미래 시각 dose(예: 22:00, 현재 15:00) tap → sheet 미노출 + SnackBar "아직 예정된 복용입니다"
- [ ] **TC-06 과거 자동 missed 격상**: 며칠 전 활성 schedule의 미기록 슬롯이 caled에서 `missed`로 보임 (이전엔 `pending`)
- [ ] **TC-07 과거 자동 missed → taken toggle**: TC-06 카드 tap → "이미 복용했어요" → DB에 log row 신규 생성 + `taken` 표시
- [ ] **TC-08 과거 자동 missed → undo (재 미기록)**: 직접 DB log 삭제 시 다시 missed 표시 (격상이 read-only임 확인)
- [ ] **TC-09 monthly dot 갱신**: TC-01~TC-03 진행 중 월간 그리드 dot 색 변경 즉시 반영
- [ ] **TC-10 today summary 갱신**: 오늘 dose toggle → SummaryCard `done`/`pending`/`missed` 카운트 즉시 변경
- [ ] **TC-11 report 동기화**: weekly/monthly report 진입 후 toggle → 진입 중인 화면 invalidate 또는 다음 진입 시 카운트 변경 (Calendar 호출 컨텍스트 기준)
- [ ] **TC-12 Home 정합화**: Home `_openEditSheet` 호출 (기존 markTaken-only 케이스) → 새 sheet props로 노출 + missed 옵션 가능 → markMissed 시 카드 갱신
- [ ] **TC-13 호환성**: 다른 호출부 또는 기존 호출 시그니처(props 미지정) 정상 컴파일 + 기존 라벨 ("오늘"/"어제") 그대로
- [ ] **TC-14 startDate 이전 슬롯**: 등록일 이전의 활성 schedule 슬롯은 여전히 `pending` (자동 missed 격상 제외 가드 확인)
- [ ] **TC-15 빠른 연타**: 동일 dose에 markTaken → 즉시 markMissed → 최종 missed (upsert race 무해)

### 8.3 회귀 체크

- [ ] past-dose-edit `PastDosesBackfillSheet` 흐름 정상 (등록 직후 backfill — 본 변경 영향 없음)
- [ ] catalog-phase-2c "시각 추가" 분기 정상
- [ ] Home `BundleNotificationSheet` 흐름 정상
- [ ] Home "먹었어요" highlight 버튼 (highlight = 첫 미래 pending) 정상
- [ ] `dart analyze` clean (신규 0)
- [ ] `flutter build apk --debug` 성공

---

## 9. Clean Architecture

### 9.1 Layer Structure (Flutter — pill_mate 실제 구조)

| Layer | Responsibility | Location |
|-------|---------------|----------|
| **Presentation** | Screens, widgets, sheets, flow state | `lib/features/*/presentation/`, `lib/core/widgets/` |
| **Data/Repository** | DB/Drift 접근, 도메인 객체, 계산 helper | `lib/features/*/data/`, `lib/core/database/` |
| **Core / Cross-cutting** | 알림, 권한, 라우터, 테마 | `lib/core/` |

### 9.2 본 feature의 Layer 할당

| Component | Layer | Location | 변경 |
|-----------|-------|----------|------|
| `EditRecordSheet` | Presentation (cross-cutting widget) | `lib/core/widgets/sheets/edit_record_sheet.dart` | **수정** |
| `_RecordCard` | Presentation (feature widget) | `lib/features/calendar/presentation/calendar_screen.dart` (내부 private class) | **수정** |
| `_CalendarScreenState._openEditSheet` + `_relativeLabel` | Presentation | 동 파일 | **신규** |
| `_HomeScreenState._openEditSheet` | Presentation | `lib/features/home/presentation/home_screen.dart` | **수정 (정합화)** |
| `computeDosesForDay` 분기 | Data (presentation-agnostic free function) | `lib/features/medication/data/intake_repository.dart` | **수정** |

### 9.3 의존 방향

```
EditRecordSheet (Presentation, sheet)
        ▲
        │ 호출/결과
CalendarScreen · HomeScreen (Presentation)
        │
        ▼ data layer 호출
IntakeRepository.markTaken / markMissed (Data, 기존)
        │
        ▼
AppDatabase / Drift (Infrastructure)

computeDosesForDay (Data free function) — Presentation에서 직접 호출 (provider 경유)
```

- Sheet → Data 직접 호출 없음
- screen이 invalidate 호출 — provider family는 Data 레이어가 소유, screen은 key만 알면 됨

---

## 10. Coding Convention Reference

### 10.1 Project Conventions (pill_mate)

| Target | Rule | Example |
|--------|------|---------|
| Dart 파일명 | snake_case.dart | `edit_record_sheet.dart` |
| Widget class | PascalCase | `EditRecordSheet` |
| Static factory | `show(BuildContext, {...})` 패턴 | `EditRecordSheet.show` |
| Sheet 위치 | `lib/core/widgets/sheets/` | 기존 위치 그대로 |
| 색상 토큰 | `AppColors.*` 만 사용 | hex literal 금지 |
| 버튼 | `AppButton(variant: ..., fullWidth: true)` | 기존 sheet 패턴 |
| Deprecated 표시 | `@Deprecated('Use X')` | yesterday flag |
| 한국어 주석 | 의도/edge case | 기존 톤 따름 |

### 10.2 본 feature의 Conventions

| Item | Convention Applied |
|------|-------------------|
| Sheet props 추가 | 모두 named, default 값 — backward compatible |
| Sheet enum 확장 | 기존 항목 순서 유지 (`keep`, `markTaken`, `markMissed`) |
| `_openEditSheet` 명명 | Calendar/Home 동일 이름(파일별 private) — 의도 일관 |
| invalidate 명시 | helper 추출 없이 호출부에서 직접 — 중복 발견 시 ENH |
| `_relativeLabel` 명명 | 두 화면에 동일 시그니처 — 추출 시 `lib/core/utils/relative_date.dart` 후보 |

---

## 11. Implementation Guide

### 11.1 File Structure (변경 후)

```
lib/
├── core/widgets/sheets/
│   └── edit_record_sheet.dart                (modify — props/enum/분기)
└── features/
    ├── calendar/presentation/
    │   └── calendar_screen.dart              (modify — _RecordCard tap, _openEditSheet, _relativeLabel)
    ├── home/presentation/
    │   └── home_screen.dart                  (modify — _openEditSheet 정합화, markMissed 분기, _relativeLabel)
    └── medication/data/
        └── intake_repository.dart            (modify — computeDosesForDay 분기 추가)
```

> **신규 파일 없음**. 모두 기존 파일 수정.

### 11.2 Implementation Order

1. [ ] **Step 1 — `EditRecordSheet` 확장**
   - enum에 `markMissed` 추가
   - `show()` 시그니처에 `dateLabel:String?` / `currentStatus:IntakeStatus?` / `allowMissed:bool=false` 추가
   - `yesterday`는 `@Deprecated` + default fallback 유지
   - `_Header` 부제목: `dateLabel ?? (yesterday ? '어제 ' : '') + ' 드셨나요?'` 분기
   - `_MedInfoCard` 하단 텍스트: `currentStatus`에 따라 "이미 복용"/"예정"/"놓침"/"건너뜀" 표기 (null이면 기존 "놓침으로 표시됨" 유지 = 호환)
   - 액션 row: §5.1 표 그대로 분기 (라벨/variant/return enum)

2. [ ] **Step 2 — `_RecordCard` tap-aware**
   - `onTap: VoidCallback` 필수 prop 추가
   - `InkWell`로 wrap, `borderRadius` 18 — ripple 정확히 카드 클립
   - 호출부에서 `onTap: () => _openEditSheet(r)`

3. [ ] **Step 3 — Calendar `_openEditSheet` + `_relativeLabel`**
   - `_CalendarScreenState`에 `_relativeLabel(DateTime)` private function 추가
   - `_openEditSheet(DoseInstance dose)`:
     - 미래 가드: `dose.scheduledAt.isAfter(DateTime.now())` → SnackBar + return
     - `EditRecordSheet.show(allowMissed: true, currentStatus: dose.status, dateLabel: _relativeLabel(dose.scheduledAt))`
     - choice 분기: markTaken/markMissed → repo 호출 → invalidate → SnackBar
   - invalidate set:
     ```dart
     ref.invalidate(dayDosesProvider(_dateOnlyOf(dose.scheduledAt)));
     ref.invalidate(monthMarksProvider((year: dose.scheduledAt.year, month: dose.scheduledAt.month)));
     ref.invalidate(todayCountsProvider);
     ref.invalidate(nextDoseProvider);
     // reports family — 현재 Calendar에서 직접 watch하지 않으나 진입 시 fresh 보장 위해 호출 컨텍스트에 추가
     ```

4. [ ] **Step 4 — `computeDosesForDay` 과거 missed 격상**
   - §3.4 diff intent 적용
   - `_dateOnly(date).isBefore(_dateOnly(nowTime))` 케이스에 `!beforeStart && !hasLog` 조건 그대로

5. [ ] **Step 5 — Home `_openEditSheet` 정합화**
   - 기존 hard-coded `yesterday: false` → `dateLabel: _relativeLabel(dose.scheduledAt)`
   - `allowMissed: true` 추가
   - `currentStatus: dose.status` 추가
   - choice에 `markMissed` 분기 추가 → `repo.markMissed(...)` + invalidate
   - SnackBar 메시지 분기 추가

6. [ ] **Step 6 — `flutter analyze`**
   - 신규 warning 0 확인
   - deprecated `yesterday` 사용처가 본 변경 외 없는지 grep

7. [ ] **Step 7 — Manual TC**
   - §8.2 TC-01 ~ TC-15 수행
   - §8.3 회귀 체크

### 11.3 Pseudocode — Calendar `_openEditSheet`

```dart
// _CalendarScreenState

Future<void> _openEditSheet(DoseInstance dose) async {
  final now = DateTime.now();
  if (dose.scheduledAt.isAfter(now)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('아직 예정된 복용입니다')),
    );
    return;
  }

  final choice = await EditRecordSheet.show(
    context,
    medName: dose.medicationName,
    category: dose.category ?? 'sup',
    time: dose.timeOfDay,
    dateLabel: _relativeLabel(dose.scheduledAt),
    currentStatus: dose.status,
    allowMissed: true,
  );
  if (!context.mounted) return;

  final repo = ref.read(intakeRepositoryProvider);
  String? feedback;
  try {
    switch (choice) {
      case EditRecordChoice.markTaken:
        await repo.markTaken(
          medicationId: dose.medicationId,
          scheduleId: dose.scheduleId,
          scheduledAt: dose.scheduledAt,
        );
        feedback = "'이미 복용'으로 수정했어요";
        break;
      case EditRecordChoice.markMissed:
        await repo.markMissed(
          medicationId: dose.medicationId,
          scheduleId: dose.scheduleId,
          scheduledAt: dose.scheduledAt,
        );
        feedback = "'놓침'으로 수정했어요";
        break;
      case EditRecordChoice.keep:
      case null:
        return;
    }
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('변경 실패: $e')),
    );
    return;
  }

  if (!context.mounted) return;
  final day = DateTime(
    dose.scheduledAt.year, dose.scheduledAt.month, dose.scheduledAt.day,
  );
  ref.invalidate(dayDosesProvider(day));
  ref.invalidate(monthMarksProvider(
    (year: dose.scheduledAt.year, month: dose.scheduledAt.month),
  ));
  ref.invalidate(todayCountsProvider);
  ref.invalidate(nextDoseProvider);
  // reports family는 호출 컨텍스트에 따라 invalidate(현 화면에 없음)

  if (feedback != null) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(feedback)));
  }
}
```

### 11.4 Pseudocode — Home `_openEditSheet` 정합화 (diff intent)

```dart
// before (home_screen.dart:201-217)
Future<void> _openEditSheet(BuildContext context, DoseInstance dose) async {
  final choice = await EditRecordSheet.show(
    context,
    medName: dose.medicationName,
    category: dose.category ?? 'sup',
    time: dose.timeOfDay,
    yesterday: false,                       // ← 하드코딩
  );
  if (choice == EditRecordChoice.markTaken) {
    await ref.read(intakeRepositoryProvider).markTaken(
          medicationId: dose.medicationId,
          scheduleId: dose.scheduleId,
          scheduledAt: dose.scheduledAt,
        );
  }
}

// after
Future<void> _openEditSheet(BuildContext context, DoseInstance dose) async {
  final choice = await EditRecordSheet.show(
    context,
    medName: dose.medicationName,
    category: dose.category ?? 'sup',
    time: dose.timeOfDay,
    dateLabel: _relativeLabel(dose.scheduledAt),
    currentStatus: dose.status,
    allowMissed: true,
  );
  if (!context.mounted) return;

  final repo = ref.read(intakeRepositoryProvider);
  String? feedback;
  try {
    switch (choice) {
      case EditRecordChoice.markTaken:
        await repo.markTaken(
          medicationId: dose.medicationId,
          scheduleId: dose.scheduleId,
          scheduledAt: dose.scheduledAt,
        );
        feedback = "'이미 복용'으로 수정했어요";
      case EditRecordChoice.markMissed:
        await repo.markMissed(
          medicationId: dose.medicationId,
          scheduleId: dose.scheduleId,
          scheduledAt: dose.scheduledAt,
        );
        feedback = "'놓침'으로 수정했어요";
      case EditRecordChoice.keep:
      case null:
        return;
    }
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('변경 실패: $e')),
    );
    return;
  }

  if (!context.mounted) return;
  final day = DateTime(
    dose.scheduledAt.year, dose.scheduledAt.month, dose.scheduledAt.day,
  );
  ref.invalidate(dayDosesProvider(day));
  ref.invalidate(monthMarksProvider(
    (year: dose.scheduledAt.year, month: dose.scheduledAt.month),
  ));
  ref.invalidate(todayCountsProvider);
  ref.invalidate(nextDoseProvider);

  if (feedback != null) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(feedback)));
  }
}
```

### 11.5 Pseudocode — `EditRecordSheet` 액션 row 분기 (build 내부)

```dart
// Sheet body의 액션 row 일부
Widget _buildActions(BuildContext context) {
  final st = currentStatus;
  final left = _resolveLeftAction(st, allowMissed);
  final right = _resolveRightAction(st, allowMissed);
  return Row(
    children: [
      Expanded(
        child: AppButton(
          label: left.label,
          variant: left.variant,
          fullWidth: true,
          onPressed: () => Navigator.of(context).pop(left.choice),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: AppButton(
          label: right.label,
          variant: right.variant,
          fullWidth: true,
          onPressed: () => Navigator.of(context).pop(right.choice),
        ),
      ),
    ],
  );
}

class _ActionSpec {
  const _ActionSpec({required this.label, required this.variant, required this.choice});
  final String label;
  final AppButtonVariant variant;
  final EditRecordChoice choice;
}

_ActionSpec _resolveLeftAction(IntakeStatus? st, bool allowMissed) {
  // §5.1 표 그대로 분기 — 짧은 switch
  if (!allowMissed) {
    return const _ActionSpec(
      label: '그대로 둘게요',
      variant: AppButtonVariant.primaryTint,
      choice: EditRecordChoice.keep,
    );
  }
  switch (st) {
    case IntakeStatus.taken:
      return const _ActionSpec(
        label: '놓침으로 수정',
        variant: AppButtonVariant.primaryTint,
        choice: EditRecordChoice.markMissed,
      );
    case IntakeStatus.missed:
    case null:
      return const _ActionSpec(
        label: '그대로 둘게요',
        variant: AppButtonVariant.primaryTint,
        choice: EditRecordChoice.keep,
      );
    case IntakeStatus.pending:
    case IntakeStatus.skipped:
      return const _ActionSpec(
        label: '놓침으로 표시',
        variant: AppButtonVariant.primaryTint,
        choice: EditRecordChoice.markMissed,
      );
  }
}

_ActionSpec _resolveRightAction(IntakeStatus? st, bool allowMissed) {
  // taken인 경우: 좌측이 markMissed이므로 우측은 keep
  if (allowMissed && st == IntakeStatus.taken) {
    return const _ActionSpec(
      label: '그대로 둘게요',
      variant: AppButtonVariant.primary,
      choice: EditRecordChoice.keep,
    );
  }
  return const _ActionSpec(
    label: '이미 복용했어요',
    variant: AppButtonVariant.primary,
    choice: EditRecordChoice.markTaken,
  );
}
```

### 11.6 Invalidate 의존 매핑 표

| Action source | Provider family | Key derivation |
|---|---|---|
| Calendar tap | `dayDosesProvider` | `DateTime(scheduledAt.y, m, d)` |
| Calendar tap | `monthMarksProvider` | `(year: scheduledAt.year, month: scheduledAt.month)` |
| Calendar/Home tap | `todayCountsProvider` | (key-less, 단일) |
| Calendar/Home tap | `nextDoseProvider` | (key-less, 단일) |
| Home tap | `dayDosesProvider` | 동일 (today) |
| Home tap | `monthMarksProvider` | 동일 (today's year/month) |
| (선택) | `reports*Provider` | 호출 컨텍스트가 watch 중일 때만 |

> reports family는 사용자가 직접 진입할 때 fresh fetch되므로 v1에서는 화면 진입에 의존. 필요 시 ENH로 추가.

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 0.1 | 2026-05-22 | Initial draft | 정성훈 |
