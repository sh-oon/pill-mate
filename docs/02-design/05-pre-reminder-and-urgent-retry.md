---
template: design
version: 1.0
feature: phase-4-pre-and-urgent
date: 2026-05-19
author: gamja
project: pill-mate
platform: Flutter (iOS + Android)
status: Draft
---

# 05 — N분 전 사전 알림 + Urgent 미복용 재알림

> **Summary**: 예정 시각보다 N분 전 "곧 복용 시간" 알림을 한 번 더 띄우고, 예정 시각 후 M분마다 사용자 액션 없을 시 "긴급" 알림을 K회까지 재발화. 기존 `AlarmScheduler`가 비슷한 컨셉의 단발 ID 규칙(per-intakeLog)을 이미 갖고 있어 이를 schedule 단위로 변형해 통합.

## 1. 문제 / Why

### 현재 동작
- 예정 시각에 단 한 번 알림 ("복용 시간")
- 사전 알림 / 재알림 일체 없음

### 사용자 가치
- 사전 알림: 운전/회의 중 진입을 미리 준비 가능 (예: 5분 전)
- urgent 재알림: 한 번 무시한 알림이 묻혀 정말로 복약 누락되는 가장 빈번한 실패 케이스 방어
- 처방약 (혈압/당뇨)은 누락 시 임상적 의미 큼 → 가장 강한 가치

## 2. 제약

- iOS 알림 한도 64개. 한 약당 (사전 1 + on-time 1 + urgent N)을 더하면 빠르게 한도 도달
- urgent 알림은 사용자 액션 후 즉시 취소되어야 함 (안 그러면 계속 울림 → bad UX)
- 백그라운드 isolate에서도 urgent 취소가 작동해야 함 (액션 누른 즉시 다음 5분 후 안 울려야)

## 3. 접근

### 옵션 비교

| 옵션 | 설명 | 평가 |
|---|---|---|
| **A. schedule 단위로 사전/onTime/urgent 묶음 등록** | 한 schedule당 사전 N분 전 daily + onTime daily + urgent 단발 K개 등록 | **채택** — 패턴 일관 |
| B. 모두 단발로 등록 후 매일 재등록 | OS 한도 빠르게 초과 + 사용자 미접속 시 큐 고갈 | 폐기 |
| C. notification group / summary 사용 | iOS/Android 알림 그룹 묶음 — 사용자 무시한 알림을 일괄 표시 | 보조 (v2) |

### Schedule 단위 라이프사이클

```
약 등록 (sched.remindBeforeMinutes = 5, urgentRepeatMinutes = 5, urgentMaxRepeats = 3):
  알림 등록:
    - 사전 5분 전: daily 반복 (cid: reminderId)
    - onTime: daily 반복 (cid: onTimeId, 기존)
    - urgent: 단발 3개 (cid: urgentId, ↓아래 ID 규칙)
  
  -> 단발 urgent들은 "오늘분"만 등록. 다음날 분은 부팅 syncAll() 또는 사용자 액션 시 갱신.

사용자 액션 (taken/skipped):
  cancelUrgentForToday(scheduleId) — 오늘 등록된 urgent 알림 3개 모두 취소

부팅 syncAll():
  모든 active schedule에 대해 사전/onTime은 daily로 유지
  urgent는 오늘 미발화분만 다시 등록 (이미 발화한 건 무시)
```

### ID 규칙 확장

기존:
- daily onTime: `scheduleId * 10`
- weekly onTime: `scheduleId * 10 + weekday(1..7)`
- snooze (01 문서): `scheduleId * 10 + 8`

추가:
- **사전 알림 daily**: `scheduleId * 10 + 9`
- **urgent 단발 n번째 (n=1..K)**: `scheduleId * 1000 + 100 + n`
  - 기존 `AlarmScheduler._kUrgentSlotBase = 100`과 패턴 일관

ID 충돌 검증: 
- daily/weekly/snooze/사전 모두 `scheduleId * 10 + [0..9]` 범위
- urgent는 `scheduleId * 1000 + [101..199]` 범위
- → 같은 scheduleId 안에서 충돌 없음 (1000 vs 10 차수 다름)
- 다른 scheduleId 간 충돌 없음 (자릿수 분리)

### Schedule 컬럼 활용

이미 정의됨:
- `remindBeforeMinutes` (int?) — null이면 사전 알림 없음
- `urgentRepeatMinutes` (int?) — null이면 urgent 비활성
- `urgentMaxRepeats` (int?) — null이면 기본값(6)

→ 스키마 변경 불필요, 코드만 활성화

## 4. 구현 계획

### Step 1. `MedicationNotificationManager._scheduleRecurring` 보강

```dart
Future<void> _scheduleDaily(Medication med, Schedule s) async {
  final next = _nextOccurrence(s.timeOfDay);
  
  // 1) 사전 알림
  if ((s.remindBeforeMinutes ?? 0) > 0) {
    final preTime = _subtractMinutes(s.timeOfDay, s.remindBeforeMinutes!);
    final preNext = _nextOccurrence(preTime);
    await _plugin.zonedSchedule(
      _preReminderIdFor(s),
      '${med.name} 복용 ${s.remindBeforeMinutes}분 전',
      '곧 복용 시간입니다.',
      preNext,
      _details(tone: NotifTone.reminder),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: _payload(s, preNext, kind: 'reminder'),
    );
  }
  
  // 2) onTime (기존)
  await _plugin.zonedSchedule(
    _dailyIdFor(s),
    '${med.name} 복용 시간',
    _quantityHint(med),
    next,
    _details(tone: NotifTone.onTime),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    matchDateTimeComponents: DateTimeComponents.time,
    payload: _payload(s, next, kind: 'onTime'),
  );
  
  // 3) urgent 단발 — 오늘 분만
  if ((s.urgentRepeatMinutes ?? 0) > 0) {
    final max = s.urgentMaxRepeats ?? AlarmScheduler.defaultUrgentMaxRepeats;
    for (var n = 1; n <= max; n++) {
      final at = next.add(Duration(minutes: s.urgentRepeatMinutes! * n));
      await _plugin.zonedSchedule(
        _urgentIdFor(s, n),
        '⚠️ ${med.name} 미복용 알림',
        '아직 복용 체크가 되지 않았어요.',
        at,
        _details(tone: NotifTone.urgent),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        // 단발
        payload: _payload(s, next, kind: 'urgent:$n'),
      );
    }
  }
}
```

`_details(tone:)` — Phase 3의 `_details(urgent: bool)`을 enum으로 확장 (`reminder`/`onTime`/`urgent`).

### Step 2. `cancelUrgentForToday(scheduleId, max)` 추가

```dart
Future<void> cancelUrgentForToday(int scheduleId, {int max = 32}) async {
  for (var n = 1; n <= max; n++) {
    await _plugin.cancel(_urgentIdFor(s, n));
  }
}
```

### Step 3. 액션 hook (taken/skipped 시 오늘 urgent 취소)

`NotificationActionHandler` 또는 `IntakeRepository.mark` 내부에서:

```dart
await _notif.cancelUrgentForToday(scheduleId);
```

### Step 4. 부팅 syncAll() — 오늘 urgent 보강

기존 syncAll은 cancelAll → DB 기반 재구성이라 자동 동작:
- 어제 발화된 urgent들은 OS 큐에 없음
- 오늘 미발화분만 새로 등록됨 (이미 발화 시각 지난 건 `_nextOccurrence`/단순 비교로 skip)

`_scheduleDaily` 안 urgent 루프에서 `at.isAfter(now)` 가드 추가.

### Step 5. 사용자 설정 UI (선택)

- 상세 화면에 "사전 알림 N분 전" 토글/선택
- "긴급 미복용 재알림" on/off + 간격 + 최대 횟수
- 기본값: 사전 5분, urgent 5분 × 3회

v1.0에서는 합리적 기본값만, 설정 노출은 v1.1.

### Step 6. AlarmScheduler 정리

- 기존 `AlarmScheduler`는 per-intakeLog 단발이라 사용 안 됨
- Phase 3 commit에서 함수 정의는 유지, 호출 없음
- Phase 5 정리 시 deprecate 또는 manager 통합 후 삭제

## 5. 데이터/스키마 변경

- 없음 (`remindBeforeMinutes` 등 기존 컬럼 활용)

## 6. 테스트 계획

| # | 시나리오 | 기대 |
|---|---|---|
| T1 | remindBeforeMinutes=5 약 등록, 등록 시각 09:00 | 08:55 알림 + 09:00 알림 둘 다 도착 |
| T2 | urgentRepeatMinutes=5, max=3, 등록 시각 09:00, 사용자 액션 없음 | 09:05 / 09:10 / 09:15 urgent 알림 3회 |
| T3 | 09:00 알림에서 "복용 완료" 액션 | DB taken + 09:05 이후 urgent 모두 취소 |
| T4 | 등록 직후 사용자가 약 수정 (remind 5→10분) | 기존 08:55 알림 cancel + 08:50 알림 새로 등록 |
| T5 | 약 삭제 | 사전/onTime/urgent 모두 cancel |
| T6 | 시뮬: iOS 알림 한도 초과 등록 | 후순위 등록 실패, 로그 경고 |

## 7. 위험 / Out of scope

- **iOS 알림 한도**: 가장 큰 위험. 한 약 = 1(사전) + 1(onTime) + 6(urgent) = 8개. 약 8개 등록하면 64개 도달. urgent 단발은 매일 cleanup + 재등록되므로 일시적, 실효 한도는 더 여유 있음. 모니터링 필요.
- **백그라운드 isolate에서 urgent 취소**: 02 문서의 dispatcher가 `cancelUrgentForToday`를 호출할 수 있어야 안전. 02와 페어 구현 권장.
- **타임존 변경 vs 단발 urgent**: 사전/onTime은 daily 반복이라 자동 보정. urgent 단발은 사용자 timezone 변경 시 의도와 다를 수 있음 — 매일 자정에 자동 재등록 패턴이 더 안전 (단, 그건 별 작업 큼).
- **알림 피로감**: urgent 3회 × 약 5개 = 15회 알림. 사용자가 무시 학습. UI에서 "urgent 활성화 시 신중히" 안내.

## 8. 작업 분량 추정

- 코드: ~200줄 (manager 보강 + cancel API + 액션 hook)
- 사용자 설정 UI 추가 시: +100줄
- 테스트: 1시간 (시각 시뮬레이션)
- 총 소요: 3~4시간 (UI 제외)
