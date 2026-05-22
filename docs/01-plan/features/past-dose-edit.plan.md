---
template: plan-plus
version: 1.0
feature: past-dose-edit
date: 2026-05-22
author: 정성훈
project: pill_mate
version: 1.0.0+4
---

# past-dose-edit Planning Document

> **Summary**: 약/영양제를 오늘 신규 등록(또는 기존 약에 시각 추가)할 때, 등록 시점 기준 이미 지난 오늘 시각대에 대해 “이미 챙기셨나요?” bottom-sheet로 묻고 선택 슬롯을 `markTaken`으로 일괄 기록한다.
>
> **Project**: pill_mate (Flutter)
> **Version**: 1.0.0+4
> **Author**: 정성훈
> **Date**: 2026-05-22
> **Status**: Draft
> **Method**: Plan Plus (Brainstorming-Enhanced PDCA)

---

## Executive Summary

| Perspective | Content |
|-------------|---------|
| **Problem** | 오늘 늦은 시간(예: 오후 2시)에 약을 새로 등록할 경우, 같은 약의 이전 시각(예: 08:00) 슬롯은 `pending`으로 표시되지만 home/캘린더 어디에서도 "먹었어요"/상태 변경 UI가 없어서 사용자가 이미 복용한 사실을 기록할 수단이 없다. |
| **Solution** | 등록 플로우의 저장 직후·pop 직전에 조건부 `PastDosesBackfillSheet`를 띄워 오늘의 과거+활성+로그미존재 슬롯들에 대해 "이미 챙긴 것" 체크 → 선택 슬롯에 `IntakeRepository.markTaken` 일괄 호출. |
| **Function/UX Effect** | 등록 시점에 한 번에 정리 → 등록 직후 home/캘린더에 즉시 일관된 상태. home 화면 인터랙션 면적은 무손상. |
| **Core Value** | 등록 시점에 의도를 묻는다(intent-at-source) — 사후 편집 UI를 늘리지 않고 실제 문제를 발생 지점에서 해소. |

---

## 1. User Intent Discovery

### 1.1 Core Problem

오늘 등록 시 startDate가 `DateTime.now()`로 시각까지 보존되며, `intake_repository.dart:217-230`은 등록 시각 이전 슬롯을 의도적으로 `pending`으로 유지(리포트 놓침 카운트 부풀림 방지)한다. 그러나 home `_DoseRow`의 "먹었어요" 버튼은 `highlight = 첫 미래 pending 시각대`에만 노출(`home_screen.dart:619-630, 689`)되고, `EditRecordSheet`는 `missed` 슬롯에만 연결(`home_screen.dart:121`)되어 있어 — **과거+pending** 상태의 슬롯은 어떤 UI 경로로도 상태를 변경할 수 없다.

### 1.2 Target Users

| User Type | Usage Context | Key Need |
|-----------|---------------|----------|
| 본인(개인 사용자) | 오전·점심 복용 후, 오후에 앱에 약을 신규 등록 | 등록과 동시에 "이미 챙긴 것"을 표시해 home/리포트가 즉시 사실에 부합 |
| 본인 | 이미 등록된 약에 새로운 시각(예: 점심) 추가, 점심을 이미 먹은 상태 | 같은 흐름에서 과거 추가분도 기록 가능 |

### 1.3 Success Criteria

- [ ] 오늘 14:00에 신규 약을 등록(시각 08:00/13:00/20:00, daily) 시 등록 완료 후 sheet가 뜨고 08:00·13:00가 노출된다
- [ ] sheet에서 두 슬롯 모두 체크 후 "기록할게요" → home 진입 시 두 슬롯이 `taken` 배지로 표시된다
- [ ] sheet에서 "건너뛰기"/dismiss → 기존 동작과 동일(SnackBar "등록되었어요" + pop)
- [ ] 과거 시각이 없는 경우(예: 오늘 07:00에 등록 + 08:00/13:00 시각) sheet가 뜨지 않는다
- [ ] weekly 약에서 오늘 요일이 mask에 없을 때, 오늘의 과거 시각이라도 sheet에 노출되지 않는다
- [ ] catalog 중복 "시각 추가" 분기에서, 새로 추가된 시각 중 오늘 과거 + 로그 미존재만 sheet에 노출된다 (기존 시각의 today 슬롯이 이미 taken/missed인 것은 노출되지 않음)
- [ ] `_isEdit=true`(약 상세 → 편집)에서는 sheet가 뜨지 않는다

### 1.4 Constraints

| Constraint | Details | Impact |
|------------|---------|--------|
| Schedule insert는 id 미반환 (현재) | `insertWithSchedules` / `updateWithSchedules`가 schedule row id 리스트를 돌려주지 않음. `markTaken`은 `scheduleId` 필요. | Medium — Repository 서명 변경 필요 |
| 등록 직후 `_notif.syncSchedulesFor` 실행됨 | `markTaken` 내부에서도 sync를 호출 — 중복 호출이지만 멱등. | Low |
| startDate가 시각까지 보존되는 기존 의도 | "리포트 놓침 카운트 부풀리지 않기" — 본 변경은 이 의도와 충돌하지 않음(사용자 명시 선택으로만 `taken` 기록). | Low |

---

## 2. Alternatives Explored

### 2.1 Approach A: 등록 직후 backfill bottom-sheet — Selected

| Aspect | Details |
|--------|---------|
| **Summary** | `insertWithSchedules`/`updateWithSchedules` 성공 직후, 화면 pop 전에 조건부 sheet 호출 |
| **Pros** | 신규 위젯 1개 + flow 분기 한 군데로 끝. 기존 wizard/Step3 무손상. edit 모드는 자연스럽게 제외 가능. 기존 `BundleNotificationSheet`/`EditRecordSheet` 패턴 재사용 가능 |
| **Cons** | 등록 완료 → sheet 1단계가 추가됨(흐름 길이감) |
| **Effort** | Low |
| **Best For** | 작은 surface · 빠른 구현 · YAGNI 친화 (현재 상황에 부합) |

### 2.2 Approach B: Wizard에 Step 4 추가

| Aspect | Details |
|--------|---------|
| **Summary** | `Step4PastDoses` 추가, `StepProgressHeader` total을 조건부 3↔4로 변경 |
| **Pros** | 진행감이 자연스러움 — 사용자가 "등록 단계의 일부"로 인식 |
| **Cons** | `_canProceed`/`_nextLabel`/build switch/total 헤더 분기. edit 모드 분기. Step 가변 시 progress 헤더 깜빡임. 코드 변경 면적 큼 |
| **Effort** | Medium |
| **Best For** | 등록 의식(ritual) 강화가 핵심 가치일 때 |

### 2.3 Approach C: Step3 내부 인라인 섹션

| Aspect | Details |
|--------|---------|
| **Summary** | Step3 하단에 conditional section. 시각 선택 → 과거 시각 자동 미리보기 → 체크 → 등록 완료에서 함께 처리 |
| **Pros** | 다이얼로그/시트 없음 — 한 화면에서 해결 |
| **Cons** | Step3 이미 밀도 높음(times, repeat, weekly mask, interval, remind-before). 시각 편집 시 reactive 갱신 비용. UI 밀도 risk |
| **Effort** | Medium |
| **Best For** | Step3 여유가 있을 때 (현 Step3는 여유 없음) |

### 2.4 Decision Rationale

**Selected**: Approach A
**Reason**: 변경 면적이 가장 작고(신규 위젯 1 + flow 분기 1 + repo 반환값 확장 1), edit 모드 제외가 자연스러우며, 기존 sheet UI 패턴을 그대로 따른다. B는 progress 헤더 가변/edit 분기로 인한 부수 코드가 본 기능 가치 대비 과함. C는 Step3 밀도 risk.

---

## 3. YAGNI Review

### 3.1 Included (v1 Must-Have)

- [ ] `PastDosesBackfillSheet` — 시각×약 체크박스 리스트 (default unchecked) + "건너뛰기"/"기록할게요"
- [ ] **신규 등록(`insertWithSchedules`) 경로 + catalog 중복 "시각 추가"(`updateWithSchedules`, `_isEdit=false`) 경로 모두 동작**
- [ ] 노출 조건: `today + scheduledAt < now + isScheduleActiveOn(today) + IntakeLog 부재`
- [ ] 선택 슬롯에 `repo.markTaken` 반복 호출 (transaction 미사용 — 등록은 이미 성공, 부분 성공 허용)
- [ ] `_isEdit=true` 경로는 sheet 비활성(early-return)

### 3.2 Deferred (v2+ Maybe)

| Feature | Reason for Deferral | Revisit When |
|---------|---------------------|--------------|
| "전체 선택" 토글 | 보통 1~2개 슬롯 — UX 가치 작음 | 슬롯 3개 이상이 흔해질 때 |
| 기록 후 SnackBar 별도 표시 | 기존 "등록되었어요" SnackBar로 충분 | 사용자가 명시 피드백 요구 시 |
| `skipped` 선택 옵션 | 등록 직후 "건너뛴 약"을 선택하는 use case 드묾 | 실제 필요 패턴이 관측될 때 |
| `_isEdit=true`(약 편집)에서 backfill | 편집은 dosage/메모 변경이 주 → 등록과 사용 의도 다름 | 편집 중 시각 추가 액션이 분리되면 |

### 3.3 Removed (Won't Do)

| Feature | Reason for Removal |
|---------|-------------------|
| home/캘린더의 과거 슬롯 인라인 편집 UI | 의도가 "등록 시점에서 해결"로 결정됨 — 사후 편집은 UI 면적만 늘리고 missed 의미와 충돌 |
| past-pending 슬롯을 자동 `missed`로 격상 | 기존 코드 주석(`intake_repository.dart:217-219`)에 명시된 의도("리포트 놓침 카운트 부풀리지 않기")와 충돌 |

---

## 4. Scope

### 4.1 In Scope

- [ ] `lib/core/widgets/sheets/past_doses_backfill_sheet.dart` 신규
- [ ] `lib/features/medication/data/medication_repository.dart` — `insertWithSchedules`/`updateWithSchedules` 반환에 `scheduleIds: List<int>` 추가 (Dart record)
- [ ] `lib/features/medication/presentation/add/medication_add_flow.dart` `_save()` 내부 backfill 단계 삽입 (insert 경로 + "시각 추가" 경로)
- [ ] 신규 등록 / catalog 중복 "시각 추가" 모두 커버
- [ ] `IntakeLog` 부재 가드 (slot이 이미 logged 상태면 노출 제외)

### 4.2 Out of Scope

- `_isEdit=true`(약 상세 → 편집)에서의 backfill (YAGNI Review §3.2)
- "전체 선택" 토글 (§3.2)
- `skipped` 선택 (§3.2)
- 별도 SnackBar 피드백 (§3.2)
- home/캘린더 사후 편집 (§3.3)
- past-pending 자동 missed 격상 (§3.3)

---

## 5. Requirements

### 5.1 Functional Requirements

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-01 | `PastDosesBackfillSheet.show(context, slots)` static 메서드 제공. 반환: `Set<int>?` (선택 인덱스 set, `null` = dismiss=skip) | High | Pending |
| FR-02 | sheet 내 각 slot row: 시각(HH:mm) + 약 이름 + 분량 라벨 + 체크박스(default off). 탭 시 토글. | High | Pending |
| FR-03 | "건너뛰기" 버튼 → `pop(null)` 또는 `pop(<{}>)`. "기록할게요" 버튼 → `pop(selected)`. | High | Pending |
| FR-04 | `insertWithSchedules`는 `({int medicationId, List<int> scheduleIds})` record를 반환. `updateWithSchedules`는 `List<int> scheduleIds`를 반환. 기존 caller 모두 갱신. | High | Pending |
| FR-05 | `medication_add_flow._save()`에서 신규 등록 성공 후 backfill 후보 계산: 등록 시 사용한 `_times`와 반환된 `scheduleIds`로 `(t, scheduleId)` 매핑 → 오늘 + `combineDateAndTime(today, t).isBefore(now)` + `isScheduleActiveOn(schedule, today)` + `IntakeLog 부재`인 슬롯만 채택. | High | Pending |
| FR-06 | catalog 중복 "시각 추가"(`updateWithSchedules` 호출 분기)에서도 동일 후보 계산. 이때 schedule rows를 다시 query해서 startDate/repeatKind 등 활성 판정에 사용. | High | Pending |
| FR-07 | 후보 없으면 sheet 미노출 → 기존 SnackBar + pop 흐름 유지. | High | Pending |
| FR-08 | 후보 ≥ 1이면 `PastDosesBackfillSheet.show` await. 선택 슬롯에 대해 `repo.markTaken(medicationId, scheduleId, scheduledAt)`을 순차 호출. 실패한 항목은 콘솔 로깅 후 진행(부분 성공 허용). | High | Pending |
| FR-09 | 기존 invalidate(`todayLogsProvider`, `trackedMedicationsStreamProvider`) 호출은 backfill 직후로 이동(이미 호출되고 있다면 그대로 유지). 결과적으로 home의 stream이 신규 schedule + 신규 IntakeLog 모두 반영. | High | Pending |
| FR-10 | `_isEdit=true` 경로는 backfill 단계 early-return (현행 동작 유지). | High | Pending |

### 5.2 Non-Functional Requirements

| Category | Criteria | Measurement Method |
|----------|----------|-------------------|
| Performance | 후보 N ≤ 10 (현실적 슬롯 수) — sheet open ~ batch mark 시간 < 500ms | 수동 측정(개발 디바이스) |
| Robustness | 부분 실패 시 등록 자체는 보존, 실패한 mark만 누락 | 로깅으로 확인 |
| 정합성 | sheet dismiss → DB mutation 없음 | 코드 리뷰 |
| Lint/Build | `dart analyze` clean, `flutter build` 성공 | CI / 로컬 |
| Convention | 기존 sheet 위젯 명명/파일 구조(`lib/core/widgets/sheets/*.dart`) 준수 | 코드 리뷰 |

---

## 6. Success Criteria

### 6.1 Definition of Done

- [ ] FR-01 ~ FR-10 구현
- [ ] `dart analyze` clean
- [ ] 수동 시나리오 검증 통과 (§1.3 Success Criteria 6항목)
- [ ] 기존 catalog-phase-2c 회귀 없음 (catalog↔tracked 1:1, "시각 추가" 분기 정상)
- [ ] PDCA Check (`gap-detector`) ≥ 90% (Design 작성 후)

### 6.2 Quality Criteria

- [ ] zero analyzer warning
- [ ] sheet 위젯이 기존 `BundleNotificationSheet`/`EditRecordSheet`의 컨벤션(handle bar, header, button row) 준수
- [ ] `markTaken` loop 내 await 누락 없음 (순차 처리)

---

## 7. Risks and Mitigation

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Repository 반환값 변경이 다른 caller에서 컴파일 에러 | Medium | Medium | grep으로 모든 caller 식별 → 일괄 갱신. `insertWithSchedules`/`updateWithSchedules` caller는 현재 `medication_add_flow.dart`에 집중되어 있음 — 영향 작음 |
| `_notif.syncSchedulesFor`가 insert + 각 markTaken에서 중복 호출됨 | Low | High | sync는 멱등(daily/weekly) — 성능 영향만, 정확성 영향 없음. 필요 시 후속 최적화 ENH로 분리 |
| sheet 노출 중 사용자가 백그라운드 → 포그라운드 복귀 시 상태 유지 | Low | Low | `showModalBottomSheet`의 기본 동작 사용. 디바이스 회전/언어 변경 무관한 짧은 인터랙션 |
| update 경로에서 새로 추가한 시각이 아닌 기존 시각이 sheet에 잘못 노출 | Medium | Low | "IntakeLog 부재" 가드로 자연 차단(기존 시각의 오늘 슬롯은 대개 taken/missed/logged 상태이거나, 정말 비어있으면 backfill 대상으로 노출되어도 의도 부합) |
| `combineDateAndTime` 경계(자정 직전 등록) | Low | Low | `isBefore(DateTime.now())` 평가는 등록 시점 기준 — 자정 넘으면 다음날 슬롯이라 후보 미포함 |

---

## 8. Architecture Considerations

### 8.1 Project Level Selection

| Level | Characteristics | Recommended For | Selected |
|-------|-----------------|-----------------|:--------:|
| **Starter** | Flutter app — features/* 모듈, Drift DB, riverpod | 개인 모바일 앱 | ✅ |
| **Dynamic** | — | — | |
| **Enterprise** | — | — | |

> 참고: 본 변경 자체는 backend/network이 없는 순수 클라이언트 UI/Repository 변경.

### 8.2 Key Decisions

| Decision | Options | Selected | Rationale |
|----------|---------|----------|-----------|
| sheet 노출 시점 | 등록 직후 / Step4 / Step3 inline | **등록 직후** | 변경 면적·flow 간섭 최소 |
| `scheduleIds` 획득 방식 | Repository 반환값 확장 / 사후 query | **반환값 확장** (Dart record) | 단일 source of truth, 중복 query 회피 |
| 부분 실패 처리 | 전체 rollback / 부분 성공 허용 | **부분 성공** | 등록 트랜잭션 이미 commit — markTaken 실패해도 등록은 유효해야 함 |
| `IntakeLog` 부재 가드 | 항상 / 업데이트 경로만 | **항상** (방어적) | 신규 경로에선 사실상 noop 가드, 업데이트 경로에선 안전성 ↑ |
| 반환 record 타입 | `(int, List<int>)` / `({int medicationId, List<int> scheduleIds})` | **named record** | 호출부 가독성, 자가 문서화 |

### 8.3 Component Overview

```
medication_add_flow.dart
  _save()
   ├─ catalog resolve
   ├─ duplicate check
   │   ├─ yes → confirm dialog → updateWithSchedules(existing.id, merged) → scheduleIds
   │   └─ no  → insertWithSchedules(draft)                                 → (medId, scheduleIds)
   ├─ _maybeBackfillTodayPast(medId, scheduleIds, draft)
   │   ├─ schedules query by ids                  (drift)
   │   ├─ filter: today + past + isActive + no log
   │   ├─ if empty → noop
   │   └─ else  → PastDosesBackfillSheet.show
   │               └─ for each selected → repo.markTaken(...)
   ├─ invalidate providers
   └─ SnackBar + pop

PastDosesBackfillSheet (NEW)
  StatefulWidget — 체크 상태 관리
  static Future<Set<int>?> show(context, {required List<PastDoseSlot> slots, required String medName})
```

### 8.4 Data Flow

```
[User] 등록 완료 tap
      │
      ▼
[_save] insert/update ──► (medId, scheduleIds)
                                │
                                ▼
                        [_maybeBackfill...]
                                │
                  ┌─────────────┴──────────────┐
                  ▼                            ▼
            schedules query             intake_logs query (oneshot)
                  │                            │
                  └──────► filter combine ◄────┘
                                │
                                ▼
                       slots: List<PastDoseSlot>
                                │
                                ▼ (empty)──► return
                            non-empty
                                │
                                ▼
                  [PastDosesBackfillSheet.show]
                                │
                                ▼
                      Set<int>? selectedIndices
                                │
                                ▼ (null/empty)──► skip
                            non-empty
                                │
                                ▼
                  for each idx → repo.markTaken(...)
                                │
                                ▼
                  invalidate providers + SnackBar + pop
```

---

## 9. Convention Prerequisites

### 9.1 Applicable Conventions

- [ ] 신규 sheet 파일은 `lib/core/widgets/sheets/` 하위에 배치 (기존 패턴)
- [ ] sheet 이름: `PastDosesBackfillSheet` (PascalCase), 파일명: `past_doses_backfill_sheet.dart` (snake_case)
- [ ] `static Future<T?> show(BuildContext, {...})` 시그니처 패턴 유지 (`EditRecordSheet.show`, `BundleNotificationSheet.show` 동일)
- [ ] sheet 헤더의 handle bar / Header / Body / Action Row 레이아웃 컨벤션 따름
- [ ] Theme: `AppColors` 토큰만 사용 (literal hex 금지)
- [ ] Repository 반환값에 Dart record (named) 사용 — 호출부 자가 문서화

---

## 10. Next Steps

1. [ ] `/pdca design past-dose-edit` — Design 문서 작성 (sheet UI 명세, `_maybeBackfillTodayPast` 의사코드, Repository 변경 diff 스케치)
2. [ ] `/pdca do past-dose-edit` — 구현 (위젯 → repo 시그니처 → flow 분기 순)
3. [ ] 수동 시나리오 검증 (§1.3 6항목)
4. [ ] `/pdca analyze past-dose-edit` — gap-detector 검증

---

## Appendix: Brainstorming Log

| Phase | Question | Answer | Decision |
|-------|----------|--------|----------|
| Intent Q1 | 핵심 문제는? | 등록 UX 개선 (등록 시점에 과거 복용을 물어봄) | home/캘린더 사후 편집이 아니라 등록 흐름 보강으로 방향 확정 |
| Intent Q2 | 과거 슬롯 범위? | 오늘 지난 시각대만 | startDate=오늘 한정, 어제/그제 backdated는 v2+ |
| Alternatives | A(등록 직후 sheet) / B(Step 4 추가) / C(Step3 inline) | A 선택 | 변경 면적 최소, edit 모드 자연 제외 |
| YAGNI | 전체 선택 토글 / SnackBar / skipped / update 경로 | update 경로만 In | "시각 추가" 분기도 동일 문제 해소 필요. 나머지는 v2+ |
| Design §1 | 아키텍쳐 OK? | OK | repo 반환값 확장 + sheet 신규 + flow 분기 단일 진입 |
| Design §2/§3 | 컴포넌트/데이터 흐름 OK? | OK | _isEdit=true 제외 / IntakeLog 부재 가드 / 부분 성공 허용 |

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 0.1 | 2026-05-22 | Initial draft (Plan Plus) | 정성훈 |
