---
template: plan-plus
version: 1.0
feature: calendar-dose-edit
date: 2026-05-22
author: 정성훈
project: pill_mate
appVersion: 3.0.0+7
---

# calendar-dose-edit Planning Document

> **Summary**: Calendar 그날 기록 카드(`_RecordCard`)를 tap하면 `EditRecordSheet`로 사후 편집 진입 — taken↔missed 양방향 토글. Home `_openEditSheet`도 같은 sheet props로 정합화하고, 미래 dose는 가드, 과거 pending은 계산상 자동 missed로 격상한다.
>
> **Project**: pill_mate (Flutter)
> **Version**: 3.0.0+7
> **Author**: 정성훈
> **Date**: 2026-05-22
> **Status**: Draft
> **Method**: Plan Plus (Brainstorming-Enhanced PDCA)

---

## Executive Summary

| Perspective | Content |
|-------------|---------|
| **Problem** | Calendar에서 임의 날짜의 dose 카드를 tap해도 아무 일이 일어나지 않아, "어제 점심 약을 늦게 먹었다 / 사실은 안 먹었다"는 사후 정정 수단이 없다. Home의 `_openEditSheet`도 `yesterday: false` 하드코딩 + `markTaken`만 가능해 양방향 toggle을 못 한다. 또한 과거 날짜의 hasLog=false 슬롯이 `pending`으로 영구 노출되어 보고서 카운트를 왜곡한다. |
| **Solution** | `_RecordCard`를 tap 가능하게 만들고 `_openEditSheet(dose)`로 `EditRecordSheet`를 호출. sheet에 `currentStatus`/`allowMissed`/`dateLabel` props를 추가해 양방향 toggle을 지원하고 Home과 공유. `IntakeRepository.markTaken`/`markMissed` upsert로 즉시 반영, 관련 providers invalidate, SnackBar 피드백. `computeDosesForDay`에 과거 날짜 자동 missed 계산을 추가한다(read-only). |
| **Function/UX Effect** | Calendar에서 어느 날의 dose든 1-tap → 2-button sheet로 정정. 월간 dot · 그날 카드 · today summary · weekly/monthly report가 즉시 갱신. 미래 dose는 의도치 않은 변경을 차단. |
| **Core Value** | "사실과 다르면 거기서 바로 고친다(edit-where-you-see)" — 사후 편집 UI를 Calendar라는 단일 자연스러운 surface로 통합하고, 기존 sheet/repo를 확장해 코드 중복 없이 일관성을 확보한다. |

---

## 1. User Intent Discovery

### 1.1 Core Problem

`calendar_screen.dart`의 `_RecordCard`는 tap handler가 없어(`calendar_screen.dart:293-347`) 표시 전용이다. 따라서 사용자는 캘린더에서 과거 날짜의 약 기록을 바꿀 수 없다. Home에는 `_openEditSheet`(`home_screen.dart:201-217`)가 있으나:
- `yesterday: false` 하드코딩(208) — 날짜 라벨 정확치 않음
- `EditRecordChoice.markTaken`만 처리 — missed로 되돌리기 불가능
- `EditRecordSheet`(`edit_record_sheet.dart`) 자체에 `keep`/`markTaken` 2버튼만 있어 missed 옵션 부재

또한 `computeDosesForDay`(`intake_repository.dart:215-281`)는 `isToday=true`인 슬롯만 자동 missed로 격상하므로(259-264), 과거 날짜의 hasLog=false 슬롯은 영구히 `pending`으로 보여 캘린더의 정확성을 해친다.

### 1.2 Target Users

| User Type | Usage Context | Key Need |
|-----------|---------------|----------|
| 본인(개인 사용자) | "어제 잊고 먹은 약을 오늘 기억" — calendar에서 어제 카드 tap | 한 번에 taken으로 정정 |
| 본인 | "어제 먹었다고 표시했는데 사실 깜빡함" | taken을 missed로 되돌림 |
| 본인 | 캘린더 월간 진입 후 임의 과거 일자의 종합 정합성 확인 | 과거 미기록 슬롯이 자동 missed로 보이고, 토글로 즉시 보정 |

### 1.3 Success Criteria

- [ ] Calendar의 그날 카드(`_RecordCard`) tap → `EditRecordSheet` 노출 (과거/오늘 모두)
- [ ] sheet에서 `markTaken` 또는 `markMissed` 선택 → DB 반영 (upsert, 기존 log 덮어쓰기 포함)
- [ ] toggle 직후 그날 카드 status 즉시 갱신 + 월간 dot 종류 변경 반영
- [ ] today summary / weekly·monthly report 카운트도 즉시 동기화
- [ ] 미래 dose(`scheduledAt > now`) tap 시 sheet 미노출 + SnackBar 안내
- [ ] 변경 완료 시 짧은 SnackBar 피드백(예: "이미 복용으로 수정했어요")
- [ ] Home `_openEditSheet`도 같은 props로 동작 (yesterday 동적, allowMissed 가능)
- [ ] 과거 날짜의 hasLog=false + isScheduleActiveOn(active) + scheduledAt<today 슬롯은 캘린더에서 `missed`로 계산되어 노출 (log 미생성, 토글로 taken 가능)

### 1.4 Constraints

| Constraint | Details | Impact |
|------------|---------|--------|
| `EditRecordSheet`는 Home에서도 사용 중 | props 추가는 backward-compatible(default 값)로 가야 함 | Medium — API 시그니처 신중 설계 |
| `IntakeRepository.mark`는 upsert 동작 | 기존 log 덮어쓰기에 안전 — 추가 변경 불필요 | Low |
| `monthMarksProvider`/`dayDosesProvider`는 family | invalidate 시 정확한 key(year/month, day) 일치 필요 | Low — 호출부 일관 |
| 과거 자동 missed는 "계산"만 — log row를 만들지 않음 | undo·정확성 모두 보존(사용자가 toggle 시 비로소 log row 생성) | Low |
| past-dose-edit Plan §3.3 "Removed: home/캘린더의 과거 슬롯 인라인 편집 UI" | 정책 reversal — 본 Plan에서 명시적으로 뒤집고, 사유 기록 | Medium — 결정 문서화 |

---

## 2. Alternatives Explored

### 2.1 Approach A: 기존 EditRecordSheet 확장 — Selected

| Aspect | Details |
|--------|---------|
| **Summary** | `EditRecordSheet`에 `allowMissed:bool` + `currentStatus:IntakeStatus` + `dateLabel:String?` props 추가, enum에 `markMissed` 추가. Calendar/Home에서 공유 |
| **Pros** | 단일 sheet — 일관된 UX. 코드 중복 없음. `yesterday` flag는 default fallback으로 호환 유지. 변경 면적 작음 |
| **Cons** | Home 호출부도 props 정합화 필요(이미 v1에 포함). props 4개 추가로 시그니처 약간 비대 |
| **Effort** | Low |
| **Best For** | 사후 편집을 1개의 표준 sheet로 운영하고 싶을 때(현 상황) |

### 2.2 Approach B: Calendar 전용 신규 sheet (RecordToggleSheet)

| Aspect | Details |
|--------|---------|
| **Summary** | Calendar 전용 sheet 신규. Home `EditRecordSheet`는 무손상 |
| **Pros** | Home에 0 영향. Calendar context(날짜 헤더 등) 자유 디자인 |
| **Cons** | Sheet 코드 ~200줄 중복. 추후 두 sheet 일관성 유지 비용. Theme/Button/Header가 거의 동일하게 반복 |
| **Effort** | Medium |
| **Best For** | Calendar UX가 Home과 크게 달라야 할 때 (현재는 그렇지 않음) |

### 2.3 Approach C: 일반화된 actions API

| Aspect | Details |
|--------|---------|
| **Summary** | `EditRecordSheet`를 `actions: List<SheetAction>` 형태로 일반화 |
| **Pros** | 가장 유연 — skipped/메모 추가가 자유. 진정한 단일 sheet |
| **Cons** | API 표면 큼. v1에서 missed 1개만 추가하는데 과한 추상. YAGNI 위반 |
| **Effort** | Medium-High |
| **Best For** | 향후 3종 이상 액션이 필요한 시점 (현재 미해당) |

### 2.4 Decision Rationale

**Selected**: Approach A
**Reason**: 변경 면적이 가장 작고, Home/Calendar의 사후 편집 일관성을 sheet 1개로 확보한다. props는 모두 default 가능 — 기존 Home 호출은 그대로 컴파일된다. C의 일반화는 현재 액션이 2~3개에 불과해 추상의 과세가 가치 초과. B는 코드 중복 비용이 본 기능의 가치 대비 과함.

---

## 3. YAGNI Review

### 3.1 Included (v1 Must-Have)

- [ ] Calendar `_RecordCard` GestureDetector + `_openEditSheet(dose)` private 메서드 신규
- [ ] `EditRecordSheet`: enum `markMissed` 추가, `allowMissed:bool=false` / `currentStatus:IntakeStatus?` / `dateLabel:String?` props 추가
- [ ] 미래 dose 가드: `dose.scheduledAt > DateTime.now()` ⇒ sheet 미노출 + SnackBar 안내
- [ ] 결과 처리: `markTaken` / `markMissed` 분기 → `IntakeRepository` 호출
- [ ] providers invalidate: `dayDosesProvider(day)`, `monthMarksProvider({year, month})`, `todayCountsProvider`, `nextDoseProvider`, `reportsProviders` 관련
- [ ] 변경 완료 SnackBar (taken/missed 메시지 분기)
- [ ] Home `_openEditSheet`도 같은 sheet props로 정합화 (yesterday → dateLabel 동적, allowMissed=true 옵션 노출 여부 결정)
- [ ] `computeDosesForDay` 과거 날짜 자동 missed 계산(read-only, log 미생성): `!isToday && date<today && !hasLog && !beforeStart` ⇒ `IntakeStatus.missed`

### 3.2 Deferred (v2+ Maybe)

| Feature | Reason for Deferral | Revisit When |
|---------|---------------------|--------------|
| `skipped` 옵션 | 실수 토글 use case가 드물고 사용자 요청 없음 | "건너뜀" 패턴이 관측될 때 |
| 메모/사유 입력 | 단순 토글이 핵심 가치 | 사용자가 사유 기록을 요구할 때 |
| 일괄 토글(그 날 전체 missed → taken) | 보통 1~2개 슬롯 | 정기 다회 복용 사용자가 늘 때 |
| Undo SnackBar 액션 | mark는 upsert라 반대 토글로 충분 | 사용자가 빠른 취소를 명시 요구할 때 |
| Sheet 날짜 라벨 정밀화("3월 5일 (화)") | "오늘/어제/N일 전" 라벨로 충분 | 라벨이 모호하다는 피드백 시 |

### 3.3 Removed (Won't Do)

| Feature | Reason for Removal |
|---------|-------------------|
| Calendar용 별도 sheet 위젯 | Approach B에서 검토 — 코드 중복 비용 > 가치 |
| `actions: List<SheetAction>` 일반화 | Approach C에서 검토 — 현 액션 수에 비해 과한 추상 |
| 과거 자동 missed 시 log row 자동 생성 | undo 자유와 의도 정합 — read-only 계산만으로 충분. log는 사용자 명시 토글 시에만 |

> **Policy reversal note**: past-dose-edit Plan §3.3은 "home/캘린더의 과거 슬롯 인라인 편집 UI"를 Removed로 두었으나, 본 Plan에서 명시적으로 뒤집는다. 사유: (a) 등록 시점 backfill(past-dose-edit)이 커버하는 use case는 "신규 등록 시점의 과거 슬롯"에 한정되며, (b) 어제 이전의 사후 정정 수요가 실제로 존재함이 본 세션에서 확인됨, (c) calendar는 의미적으로 사후 편집에 가장 자연스러운 surface임.

---

## 4. Scope

### 4.1 In Scope

- [ ] `lib/features/calendar/presentation/calendar_screen.dart` — `_RecordCard`를 `InkWell`/`GestureDetector`로 감싸 tap → `_openEditSheet(record)` 호출. `_openEditSheet` private 메서드 신규. 미래 dose 가드 + SnackBar.
- [ ] `lib/core/widgets/sheets/edit_record_sheet.dart` — enum에 `markMissed` 추가. `allowMissed:bool=false` / `currentStatus:IntakeStatus?` / `dateLabel:String?` props 추가. 본문/액션 row 토글 분기.
- [ ] `lib/features/home/presentation/home_screen.dart` — `_openEditSheet`가 새 props 사용 (`dose.scheduledAt` 기반 dateLabel 동적, allowMissed 정책에 따라 노출). `markMissed` 분기 처리.
- [ ] `lib/features/medication/data/intake_repository.dart` — `computeDosesForDay`에 과거 날짜 자동 missed 계산 추가(read-only).
- [ ] providers invalidate 정합 (호출 위치별 day/month key 확인).
- [ ] 변경 완료 SnackBar 메시지 분기 (taken/missed).

### 4.2 Out of Scope

- Calendar 전용 별도 sheet 신규 (§2.2, §3.3)
- `actions: List<SheetAction>` 일반화 (§2.3, §3.3)
- skipped 옵션 (§3.2)
- 메모/사유 입력 (§3.2)
- 일괄 토글 (§3.2)
- Undo SnackBar 액션 (§3.2)
- Sheet 날짜 라벨 풀 정밀화 (§3.2)
- 과거 자동 missed 시 log row 자동 생성 (§3.3)

---

## 5. Requirements

### 5.1 Functional Requirements

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-01 | `EditRecordSheet.show`가 다음 추가 인자를 받는다: `allowMissed:bool=false`, `currentStatus:IntakeStatus?`, `dateLabel:String?`. 기존 `yesterday:bool=false`는 deprecated 처리(default fallback으로만 사용)하되 호환 유지. | High | Pending |
| FR-02 | `enum EditRecordChoice`에 `markMissed`를 추가한다(현 `keep` / `markTaken`). | High | Pending |
| FR-03 | `EditRecordSheet` body 텍스트는 `dateLabel ?? (yesterday ? '어제' : '오늘')`로 표시. 액션 row는 `currentStatus`와 `allowMissed`에 따라: (a) `pending/missed` + `allowMissed=false`: 기존 [그대로 둘게요 / 이미 복용했어요] 유지(Home의 missed-only 호출 호환). (b) `allowMissed=true`: [놓침으로 표시 / 이미 복용했어요] — `currentStatus=taken`이면 "취소(놓침으로 표시)" 강조 라벨, `currentStatus=missed/pending`이면 "이미 복용했어요" 강조. | High | Pending |
| FR-04 | Calendar `_RecordCard`를 tap 가능하게 한다(`InkWell` 권장, ripple은 surface 위에 자연). tap 시 부모 `CalendarScreen._openEditSheet(record)` 호출. | High | Pending |
| FR-05 | `CalendarScreen._openEditSheet(dose)`는 미래 dose(`dose.scheduledAt.isAfter(DateTime.now())`)이면 즉시 SnackBar("아직 예정된 복용입니다") + return. | High | Pending |
| FR-06 | `_openEditSheet`는 `EditRecordSheet.show(allowMissed: true, currentStatus: dose.status, dateLabel: _relativeLabel(dose.scheduledAt))` 호출. `_relativeLabel`은 "오늘"/"어제"/"N일 전" 중 택일(N≥2). | High | Pending |
| FR-07 | sheet 반환이 `markTaken`이면 `intakeRepositoryProvider.markTaken(medicationId, scheduleId, scheduledAt)`. `markMissed`이면 `markMissed(...)`. `keep`/`null`이면 no-op. | High | Pending |
| FR-08 | mark 후 invalidate: `dayDosesProvider(_dateOnly(dose.scheduledAt))`, `monthMarksProvider((year: …, month: …))`, today/next/report family 중 호출 컨텍스트에 노출된 것 (정확한 의존 목록은 Design에서 확정). | High | Pending |
| FR-09 | mark 성공 후 SnackBar 표시: 분기 메시지("'이미 복용'으로 수정했어요" / "'놓침'으로 수정했어요"). | Medium | Pending |
| FR-10 | Home `_openEditSheet`는 새 sheet props로 호출하도록 정합화한다. 정책: home에서도 양방향 가능(`allowMissed: true`), `dateLabel`은 `dose.scheduledAt` 기준 동적. 기존 markTaken-only path는 새 분기로 흡수. | High | Pending |
| FR-11 | `computeDosesForDay`에 과거 날짜 자동 missed 계산을 추가: `!isToday && _dateOnly(date).isBefore(_dateOnly(nowTime)) && !hasLog && !beforeStart` ⇒ `IntakeStatus.missed`. log 생성 없음(read-only). | High | Pending |
| FR-12 | 회귀 가드: 기존 Home `BundleNotificationSheet` 흐름·"먹었어요" highlight 버튼 동작 무변경. past-dose-edit `PastDosesBackfillSheet`는 무관 — 본 변경의 영향권 밖. | High | Pending |

### 5.2 Non-Functional Requirements

| Category | Criteria | Measurement Method |
|----------|----------|-------------------|
| 정합성 | toggle 후 카드/dot/summary/report 동시 갱신 | 수동 시나리오 검증 |
| Performance | sheet open ~ mark ~ invalidate ~ rebuild < 250ms (체감 즉시) | 수동 측정 |
| 호환성 | 기존 `EditRecordSheet` 호출부(Home) 컴파일 무손상 | `dart analyze` clean |
| Robustness | 미래 dose tap 무해(sheet 미노출, side-effect 0) | 코드 리뷰 + 수동 시나리오 |
| Lint/Build | `dart analyze` clean, `flutter build` 성공 | CI / 로컬 |
| Convention | 기존 sheet API 시그니처 패턴 준수 | 코드 리뷰 |

---

## 6. Success Criteria

### 6.1 Definition of Done

- [ ] FR-01 ~ FR-12 구현
- [ ] `dart analyze` clean (신규 0)
- [ ] 수동 시나리오 검증 통과 (§1.3 8항목)
- [ ] 기존 past-dose-edit / catalog-phase-2c 회귀 없음 (등록 backfill / 1:1 normalization 정상)
- [ ] PDCA Check (`gap-detector`) ≥ 90% (Design 작성 후)

### 6.2 Quality Criteria

- [ ] zero analyzer warning
- [ ] sheet props 추가가 모두 default 가능 — 기존 호출부 변경 없이 컴파일
- [ ] mark 후 invalidate 누락으로 인한 UI 비정합 0건
- [ ] 미래 dose 가드가 모든 진입점에서 일관 적용

---

## 7. Risks and Mitigation

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| `EditRecordSheet` props 4개 추가로 시그니처 비대 | Low | Medium | Design에서 sheet API 시그니처를 한 번에 확정. 향후 `actions` 일반화는 ENH로 별도 추적 |
| 과거 자동 missed 격상이 weekly/monthly report 수치를 한 번에 크게 변동 | Medium | High | 의도된 결과(정확성 회복). 사용자 노출 변경은 release note에 기록. log 미생성이라 undo 자유 |
| Calendar tap이 너무 민감(스크롤 ↔ tap 혼동) | Low | Low | `InkWell` 사용 + `behavior: HitTestBehavior.opaque`, 카드 padding 충분 |
| Home/Calendar 양쪽 invalidate 키 불일치 | Medium | Medium | Design 단계에서 family 키 매핑 표 작성, 호출부 grep으로 확인 |
| 동일 dose에 대해 빠른 연타로 toggle race | Low | Low | upsert이므로 마지막 값이 승리 — 데이터 무결성 무해. UX는 마지막 SnackBar만 보이는 정도 |
| Home의 missed-only 케이스(현행 `_openEditSheet` 호출)가 새 props에서 의도와 다르게 동작 | Medium | Medium | FR-03 분기로 backward 시각 유지. Home 호출부 명시적으로 새 props 사용으로 마이그레이션 |

---

## 8. Architecture Considerations

### 8.1 Project Level Selection

| Level | Characteristics | Recommended For | Selected |
|-------|-----------------|-----------------|:--------:|
| **Starter** | Flutter app — features/* 모듈, Drift DB, Riverpod | 개인 모바일 앱 | ✅ |
| **Dynamic** | — | — | |
| **Enterprise** | — | — | |

> 참고: 본 변경은 backend/network이 없는 순수 클라이언트 UI/Repository 변경.

### 8.2 Key Decisions

| Decision | Options | Selected | Rationale |
|----------|---------|----------|-----------|
| Sheet 구조 | A: EditRecordSheet 확장 / B: Calendar 전용 신규 / C: actions 일반화 | **A** | 중복 0, 일관성 ↑, default props로 호환 유지 |
| 액션 셋 | taken만 / taken+missed / taken+missed+skipped | **taken+missed** | 사용자 답변 — 양방향 toggle이 핵심 use case |
| Toggle 형식 | 2버튼 고정 / 현재상태 기반 단일 토글 | **2버튼(라벨 강조 분기)** | UX 명확성 — 현재상태에 따라 라벨/강조 분기로 의도 표현 |
| 과거 자동 missed | 계산만 / log row 생성 | **계산만(read-only)** | undo 자유, 사용자 명시 토글 시에만 log row 생성 |
| 미래 dose 정책 | sheet 노출 후 비활성 / 진입 자체 차단 | **진입 차단 + SnackBar** | 의도치 않은 변경 방지, UX 단순 |
| invalidate 범위 | 그날 + 월간만 / today+report까지 | **today+report 포함** | 사용자 답변 — report 카운트 동기화가 success criteria |
| Home 정책 | 현 상태 유지 / 새 sheet props로 정합화 | **정합화** | 사용자 답변 — 일관성·중복 0 |

### 8.3 Component Overview

```
CalendarScreen
  build()
    └─ _RecordCard (NEW: InkWell)
          tap ──► _openEditSheet(record)
                    │
                    ├─ future guard
                    └─ EditRecordSheet.show(
                          allowMissed: true,
                          currentStatus: record.status,
                          dateLabel: _relativeLabel(record.scheduledAt),
                       )
                          │
                          ▼
                       choice ∈ { keep, markTaken, markMissed }
                          │
                          ├─ markTaken  → repo.markTaken(...)
                          ├─ markMissed → repo.markMissed(...)
                          └─ keep       → no-op
                          │
                          ▼
                       invalidate(dayDoses, monthMarks, todayCounts, nextDose, reports*)
                          │
                          ▼
                       SnackBar(분기 메시지)

HomeScreen._openEditSheet (정합화)
  └─ 동일한 sheet props 사용 (dateLabel 동적, allowMissed=true)

EditRecordSheet (확장)
  enum EditRecordChoice { keep, markTaken, markMissed }
  static show(..., {bool allowMissed=false, IntakeStatus? currentStatus, String? dateLabel, bool yesterday=false})

IntakeRepository.computeDosesForDay (read-only 격상)
  if (!isToday && _dateOnly(date).isBefore(_dateOnly(nowTime)) && !hasLog && !beforeStart) status = missed
```

### 8.4 Data Flow

```
[User] Calendar 그날 카드 tap
        │
        ▼
[_openEditSheet(dose)]
        │
        ├─ scheduledAt > now ──► SnackBar + return
        │
        ▼
[EditRecordSheet.show(...)] ──► choice
        │
        ├─ keep        ──► return
        ├─ markTaken   ──► repo.markTaken(medId, schedId, scheduledAt)
        └─ markMissed  ──► repo.markMissed(medId, schedId, scheduledAt)
                              │
                              ▼
                        intake_logs upsert (insert or update)
                              │
                              ▼
                        notif cancel + sync (기존 mark 내부)
                              │
                              ▼
        ref.invalidate(dayDosesProvider(_dateOnly(scheduledAt)))
        ref.invalidate(monthMarksProvider((year, month)))
        ref.invalidate(todayCountsProvider) + reports family
                              │
                              ▼
        UI rebuild: 카드 status badge, monthly dot, summary card, report counts
                              │
                              ▼
        SnackBar("'이미 복용'으로 수정했어요" / "'놓침'으로 수정했어요")
```

---

## 9. Convention Prerequisites

### 9.1 Applicable Conventions

- [ ] 신규 sheet 생성 없음 — 기존 `EditRecordSheet` 확장
- [ ] sheet props 추가는 모두 named, default 가능
- [ ] `static Future<EditRecordChoice?> show(BuildContext, {...})` 시그니처 유지
- [ ] Theme: `AppColors` 토큰만 사용
- [ ] Repository는 기존 `markTaken`/`markMissed` 활용(신규 메서드 없음)
- [ ] providers invalidate는 호출 컨텍스트에서 `ref.invalidate(...)` (helper 추출 없이 v1 직접 호출 — 중복 발견 시 ENH)
- [ ] Calendar `_RecordCard` tap target은 카드 전체(`InkWell`로 surface 포함)

---

## 10. Next Steps

1. [ ] `/pdca design calendar-dose-edit` — Design 문서 작성
       - `EditRecordSheet` props/enum diff 명세
       - `_relativeLabel(DateTime)` 의사코드
       - Calendar/Home invalidate 의존 매핑 표
       - 과거 자동 missed 격상 계산 변경 diff
2. [ ] `/pdca do calendar-dose-edit` — 구현 순서: sheet 확장 → Calendar tap → invalidate 정합 → Home 정합화 → 과거 자동 missed
3. [ ] 수동 시나리오 검증 (§1.3 8항목 + 회귀 §FR-12)
4. [ ] `/pdca analyze calendar-dose-edit` — gap-detector 검증

---

## Appendix: Brainstorming Log

| Phase | Question | Answer | Decision |
|-------|----------|--------|----------|
| Intent Q1 | 어떤 backfill 수단? | Home/캘린더 사후 편집 | past-dose-edit Plan §3.3 정책 reversal |
| Intent Q2 | 주된 진입점? | Calendar 우선(과거 dose tap) | Home은 같은 sheet props로 정합화하되 진입점 추가 없음 |
| Intent Q3 | 상태 전환 범위? | taken ↔ missed 양방향 toggle | skipped는 v2+ |
| Intent Q4 | 성공 조건(multi)? | (a) tap→sheet→toggle, (b) 카드/dot 즉시 갱신, (c) report 동기화, (d) 미래 가드 | 4개 모두 v1 |
| Alternatives | A(EditRecordSheet 확장) / B(전용 sheet) / C(actions 일반화) | A 선택 | 중복 0, 일관성 ↑ |
| YAGNI(추가) | 과거 자동 missed / Home 정합화 / SnackBar / 날짜 라벨 정밀화 | 처음 3개 In, 라벨 정밀화 Defer | "오늘/어제/N일 전"으로 v1 충분 |
| Design §1-3 | 아키텍처/컴포넌트/데이터 흐름 OK? | OK | 단일 sheet 확장, read-only 격상, family key 정합 |

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 0.1 | 2026-05-22 | Initial draft (Plan Plus) | 정성훈 |
