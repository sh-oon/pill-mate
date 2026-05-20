---
template: design
version: 1.0
feature: phase-4-interval-repeat
date: 2026-05-19
author: gamja
project: pill-mate
platform: Flutter (iOS + Android)
status: Draft
---

# 03 — N일 간격(interval) 반복 알림

> **Summary**: `RepeatKind.interval`("3일마다" 같은 N일 주기)은 OS의 `matchDateTimeComponents`로 표현 불가. 다음 occurrence만 단발로 등록하고, 사용자 액션(taken/skipped/missed) 후 다음 occurrence를 재등록하는 자동 라이프사이클을 구축.

## 1. 문제 / Why

### 현재 동작
- `MedicationNotificationManager._scheduleRecurring` 안 `RepeatKind.interval` 분기는 `debugPrint`만 함
- 사용자가 "3일마다 21:00" 같은 약을 등록해도 알림 안 옴

### 사용자 가치
- 격일/주 2~3회 복용 패턴이 약 처방에서 흔함 (예: 항히스타민, 영양제 일부)
- 시안 add wizard step 3에도 "N일 간격" 옵션 명시되어 있음

## 2. 제약

- iOS/Android `flutter_local_notifications`의 `matchDateTimeComponents`는 enum: `time` / `dayOfWeekAndTime` / `dateAndTime` / `dayOfMonthAndTime`만 지원 — N일 주기 없음
- 단발 알림은 한 번 발화 후 자동 소멸 — 다음 occurrence를 누군가 다시 등록해야 함
- 사용자가 액션 안 누르면 (앱도 안 열면) 다음 occurrence가 등록되지 않을 위험

## 3. 접근

### 옵션 비교

| 옵션 | 설명 | 평가 |
|---|---|---|
| **A. 다음 occurrence 단발 + 액션 후 재등록** | 등록 시점에 "다음 1회"만 zonedSchedule, 사용자가 액션하면 그 다음 1회 추가 등록 | **채택** (1차) — 가장 단순 |
| B. 향후 N회 미리 단발 등록 | 등록 시점에 "다음 7회"를 미리 등록 → 7일 이상 미접속 시 사라짐 | 백업으로 (A + 부팅 시 보강) |
| C. 매일 daily로 등록 후 앱이 조건 검사 후 silent 무시 | 사용자가 매일 알림 받음 — 명백한 잘못 | 폐기 |
| D. WorkManager 같은 백그라운드 작업으로 매일 새벽에 재계산 | 무거운 백그라운드 API. iOS 보장 약함 | 폐기 |

### 하이브리드 채택
- **A 우선**: 단발 등록 + 액션 후 재등록 (간단)
- **B 보강**: 앱 부팅 시 `syncAll()`에서 interval 약마다 향후 7회분 미리 채워서 일주일 미접속도 커버

### 이벤트별 라이프사이클

| 이벤트 | 동작 |
|---|---|
| 약 등록 (interval) | 다음 occurrence 1회 + 향후 6회 추가 등록 (총 7회) |
| 약 수정 | 기존 interval 알림 모두 cancel + 향후 7회 재등록 |
| 약 삭제 | 모두 cancel |
| 알람 토글 off | 모두 cancel |
| 액션 (taken/skipped) | 직후 향후 1회분 추가 등록 (큐 길이 7 유지) |
| 부팅 syncAll() | 등록된 알림 ID 목록과 DB 비교 → 부족한 occurrence 채움 |

### ID 규칙 확장

기존:
- daily: `scheduleId * 10`
- weekly: `scheduleId * 10 + weekday(1..7)`
- snooze: `scheduleId * 10 + 8`

추가:
- **interval**: `scheduleId * 100000 + dayEpoch % 100000`
  - dayEpoch = `(scheduledAt - epoch).inDays`
  - 100000으로 모듈로해서 ID 범위 안에. 충돌 가능성은 극히 낮음(평생 단위)
- 또는 더 안전한 인코딩: `scheduleId * 100000 + (occurrence sequence number)` — 각 schedule에 sequence 카운터 보관 (DB 컬럼 추가)

#### 결정: sequence 컬럼 추가

Drift `Schedules` 테이블에 `lastFiredEpochDay` (또는 `nextOccurrence`) 컬럼 추가 → schemaVersion bump.

```dart
DateTimeColumn get nextOccurrence => dateTime().nullable()();
```

또는 별도 테이블 `IntervalOccurrences(scheduleId, scheduledAt)` 만들어 등록된 향후 발생을 추적.

**선택**: 별도 테이블이 더 명확. Schedules는 정의만 담고, IntervalOccurrences가 실제 미래 큐.

```dart
class IntervalOccurrences extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get scheduleId =>
      integer().references(Schedules, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get scheduledAt => dateTime()();
  BoolColumn get notified => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {scheduleId, scheduledAt};
}
```

## 4. 구현 계획

### Step 1. 스키마 추가 + schemaVersion 2→3

- `tables/interval_occurrences.dart` 신규
- `app_database.dart` `@DriftDatabase`에 추가
- `onUpgrade(from < 3)`: `createTable(intervalOccurrences)`
- `fvm dart run build_runner build`

### Step 2. `IntervalOccurrenceRepository` 신규 (또는 IntakeRepository 확장)

API:
- `ensureQueueFor(int scheduleId, {int target = 7})` — 큐 길이가 7 미만이면 미래 occurrence 추가
- `popPast(DateTime threshold)` — 이미 지난 occurrence 제거
- `getUpcoming(int scheduleId)` → List<DateTime>

### Step 3. `MedicationNotificationManager._scheduleInterval` 구현

```dart
Future<void> _scheduleInterval(Medication med, Schedule s) async {
  final n = s.intervalDays ?? 1;
  if (n <= 0) return;
  
  // 1) DB 큐에 향후 N개 채우기
  await _occRepo.ensureQueueFor(s.id, target: 7);
  
  // 2) DB에 있는 미래 occurrence들을 모두 단발로 등록
  final upcoming = await _occRepo.getUpcoming(s.id);
  for (final at in upcoming) {
    await _plugin.zonedSchedule(
      _intervalIdFor(s, at),
      '${med.name} 복용 시간',
      _quantityHint(med),
      tz.TZDateTime.from(at, tz.local),
      _details(urgent: false),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      // matchDateTimeComponents 생략 → 단발
      payload: _payload(s, at),
    );
  }
}

int _intervalIdFor(Schedule s, DateTime at) {
  final epochDay = at.difference(DateTime(2000, 1, 1)).inDays;
  return s.id * 100000 + (epochDay % 100000);
}
```

### Step 4. 액션 후 재등록 hook

`NotificationActionHandler.handle()`에서 taken/skipped 처리 후:

```dart
if (payload.repeatKind == RepeatKind.interval) {
  await _container
      .read(medicationNotificationManagerProvider)
      .syncSchedulesFor(payload.medicationId);
}
```

`syncSchedulesFor`가 `_scheduleInterval`로 라우팅되고 큐 보강.

다만 payload에 repeatKind를 포함해야 — payload 확장:
- 기존: `dose:scheduleId:medicationId:isoScheduledAt`
- 신규: `dose:scheduleId:medicationId:isoScheduledAt:repeatKind` (옵션)

또는 단순화: 액션 후 무조건 `syncSchedulesFor(medicationId)` 호출 — daily/weekly는 멱등, interval만 보강. 일률 처리가 안전.

### Step 5. 부팅 시 큐 정리

`syncAll()`이 이미 모든 약을 reconcile하므로 자동 처리. 단 cleanup:
- `popPast(now)` — 이미 지난 occurrence DB row 삭제
- 그 후 `ensureQueueFor`

### Step 6. 약 수정 시

`updateWithSchedules` → 기존 `syncSchedulesFor` 호출 → interval이면 큐 재구축.
- 단, schedule 자체가 통째로 교체되어 `intervalOccurrences`의 FK도 cascade로 사라짐
- 새 scheduleId로 새 큐 구축

### Step 7. (선택) 알림 큐 길이 모니터링

- 등록된 OS 알림 수가 iOS 64 한도 근접 시 경고
- 한 약당 7개 × 약 10개 = 70개 — 이미 한도 초과 가능
- 대안: target=3 또는 사용자 설정으로 조정

## 5. 데이터/스키마 변경

- 신규 테이블 `interval_occurrences (id, schedule_id, scheduled_at, notified)`
- schemaVersion 2 → 3
- `onUpgrade`에 `createTable` 마이그레이션

## 6. 테스트 계획

| # | 시나리오 | 기대 |
|---|---|---|
| T1 | 약 등록 (interval 3일, 09:00) | DB `interval_occurrences`에 7개 row, OS 알림 큐에 7개 |
| T2 | 첫 occurrence 도래 → "복용 완료" 액션 | IntakeLog `taken` 기록 + 새 occurrence 추가되어 큐 길이 7 유지 |
| T3 | 일주일 앱 미접속 후 부팅 | `popPast` 정리 + 큐 보강으로 7개 유지 |
| T4 | interval 약 수정 (3일 → 5일) | 기존 큐 cascade 삭제 + 새 큐 7개 생성 |
| T5 | interval 약 삭제 | OS 알림 7개 모두 취소 + DB row 0 |
| T6 | iOS 알림 한도 초과 시뮬 | 로그 경고 + 후순위 등록 실패 무시 |

## 7. 위험 / Out of scope

- **iOS 64 알림 한도**: interval 약이 많으면 다른 약 알림 등록 실패 가능. 우선순위 정책 필요 (예: 가까운 occurrence 우선).
- **장기간 미접속 시 큐 고갈**: 7회분(약 3주) 가정. 더 길어지면 사용자가 앱 한 번 열어야 보강됨. UX 명세에 안내.
- **시간대 변경**: 사용자가 비행기 모드 등으로 timezone이 바뀌면 미리 등록한 단발 알림들이 의도와 다른 시각에 발화. flutter_local_notifications가 자동 보정해주는지 검증 필요.
- **백그라운드 isolate에서 재등록**: 02 문서의 dispatcher가 `scheduleSnooze`처럼 `_scheduleInterval` 호출 가능해야 함. 큐 보강이 main isolate에서만 일어나면 백그라운드 액션 후 OS 큐 길이가 6으로 줄어들고 다음 부팅 때 보강됨 — 허용 가능.
- **DST(서머타임)**: 한국 환경에선 비적용. 글로벌 출시 시 timezone 패키지 의존하면 정상 처리.

## 8. 작업 분량 추정

- 코드: ~400줄 (스키마 + repository + manager 분기 + 액션 hook + cleanup)
- 마이그레이션 테스트: 30분
- 수동 시나리오 테스트: 1시간
- 총 소요: 4~5시간
