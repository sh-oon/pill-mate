---
template: design
version: 1.0
feature: phase-4-snooze
date: 2026-05-19
author: gamja
project: pill-mate
platform: Flutter (iOS + Android)
status: Draft
---

# 01 — Snooze 일회성 알림 ("10분 후" 액션)

> **Summary**: 알림에서 "10분 후" 액션을 누르면, 10분 뒤에 같은 약/슬롯 정보를 가진 알림이 한 번 더 발화. Phase 3에서 `TODO`로 남긴 가장 작은 갭이지만, 단발 알림 등록 패턴을 여기서 확립해 03(interval), 05(urgent)에 재사용.

## 1. 문제 / Why

### 현재 동작
- `NotificationActionHandler.handle()`의 `actionSnooze` 분기는 `debugPrint`만 함
- 사용자가 알림 액션 "10분 후"를 눌러도 아무 일도 일어나지 않음

### 사용자 가치
- 진료실/회의 중 알림이 와도 한 번 더 미룰 수 있어야 일상에서 신뢰 가능
- 시안의 번들 알림 sheet에도 "1시간 뒤에" 버튼이 있어 이미 사용자 모델에 존재

## 2. 제약

- iOS: 등록된 로컬 알림 상한 약 64개 — 동시에 너무 많이 등록 안 됨
- 백그라운드 isolate에서는 `_globalHandler == null`이라 즉시 등록 불가 — 큐잉 필요 (02 문서와 연결)
- 한 슬롯에서 사용자가 스누즈를 여러 번 누르면 ID 충돌 방지 필요

## 3. 접근

### 옵션 비교

| 옵션 | 설명 | 평가 |
|---|---|---|
| **A. 별도 일회성 알림 등록** | `_plugin.zonedSchedule`을 `matchDateTimeComponents` 없이 호출 → 한 번만 발화 | **채택** — 단순, OS native |
| B. 기존 daily 알림을 10분 뒤로 한 번 이동 | 복잡: 다음날부터 원래 시각 복귀 필요 → 매우 어려움 | 폐기 |
| C. 앱 측 타이머로 자체 발화 | 백그라운드에서 타이머 안 돎 → 사용 불가 | 폐기 |

### A 채택 이유
- daily 반복 알림은 그대로 두고 (내일도 같은 시각 울려야 함)
- 스누즈 알림은 별개의 ID로 등록되어 10분 뒤 한 번만 발화 후 자동 소멸
- 라이프사이클이 단순

### ID 규칙 확장

기존:
- daily: `scheduleId * 10`
- weekly: `scheduleId * 10 + weekday(1..7)`

추가:
- **snooze**: `scheduleId * 10 + 8` (weekday 1..7과 충돌 회피, 단일 스누즈만 허용)

연속 스누즈 시: 새 스누즈는 기존 스누즈를 덮어쓰기 (cancel 후 새로 등록) — 사용자가 5번 누르면 마지막 5번째 시각만 살아남음. 의도된 동작.

## 4. 구현 계획

### Step 1. `MedicationNotificationManager`에 `scheduleSnooze` API 추가

```dart
/// 한 슬롯에 대해 [delay] 뒤 일회성 스누즈 알림 등록.
/// 같은 슬롯의 기존 스누즈는 cancel 후 새로.
Future<void> scheduleSnooze({
  required int scheduleId,
  required int medicationId,
  required DateTime originalScheduledAt,
  Duration delay = const Duration(minutes: 10),
}) async {
  await _plugin.cancel(_snoozeIdFor(scheduleId));
  final med = await (_db.select(_db.medications)
        ..where((m) => m.id.equals(medicationId)))
      .getSingleOrNull();
  if (med == null || med.archived) return;

  final when = tz.TZDateTime.from(
    DateTime.now().add(delay),
    tz.local,
  );

  await _plugin.zonedSchedule(
    _snoozeIdFor(scheduleId),
    '${med.name} 복용 시간 (다시 알림)',
    _quantityHint(med),
    when,
    _details(urgent: false),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    // matchDateTimeComponents 생략 → 한 번만 발화
    payload: _payload(
      // 원래 scheduledAt 유지 — 액션 핸들러가 같은 슬롯으로 인식
      schedule: /* ... */,
      when: originalScheduledAt,
    ),
  );
}

int _snoozeIdFor(int scheduleId) => scheduleId * 10 + 8;
```

### Step 2. `cancelForMedication`/`cancelSchedule` 확장

스누즈 ID도 같이 cancel하도록.

```dart
Future<void> _cancelSchedule(Schedule s) async {
  await _plugin.cancel(_dailyIdFor(s));
  for (var wd = 1; wd <= 7; wd++) {
    await _plugin.cancel(_weeklyIdFor(s, wd));
  }
  await _plugin.cancel(_snoozeIdFor(s.id)); // 추가
}
```

### Step 3. `NotificationActionHandler.actionSnooze` 분기 실 구현

```dart
case NotificationChannels.actionSnooze:
  await _container
      .read(medicationNotificationManagerProvider)
      .scheduleSnooze(
        scheduleId: payload.scheduleId,
        medicationId: payload.medicationId,
        originalScheduledAt: payload.scheduledAt,
      );
  break;
```

### Step 4. 사용자가 스누즈 알림에서 액션 누른 경우

- 스누즈 알림의 payload는 원래 `scheduledAt`을 그대로 가짐
- "복용 완료" 누름 → 기존 markTaken 동작 (원래 슬롯에 기록)
- "10분 후" 또 누름 → scheduleSnooze 다시 호출 → 같은 ID에 덮어쓰기

### Step 5. UI 측 "스누즈 가능" 표시 (선택)

- 홈의 missed/scheduled 카드에 "다시 알림"으로 스누즈 버튼 노출
- v1.0에서는 OS 알림에서만 가능, 앱 내 트리거는 v1.1 이후

## 5. 데이터/스키마 변경

- 없음. 시스템 알림 큐만 사용.

## 6. 테스트 계획

| # | 시나리오 | 기대 |
|---|---|---|
| T1 | 등록 시각 도래 → 알림 도착 → "10분 후" 탭 | 10분 뒤 같은 약 알림 한 번 더 도착, 원래 daily 알림은 내일 같은 시각 그대로 |
| T2 | 스누즈 알림에서 "복용 완료" 탭 | IntakeLog `status=taken`, `actedAt=now` (`scheduledAt`은 원래 시각 그대로) |
| T3 | 약 삭제 직후 미리 등록된 스누즈가 있는 경우 | 스누즈 알림도 같이 취소되어 발화 안 됨 |
| T4 | 같은 슬롯에 스누즈 2번 연속 | 첫 번째 스누즈 알림은 취소, 두 번째만 살아 발화 |

## 7. 위험 / Out of scope

- **백그라운드 isolate에서 스누즈 트리거** → 02 문서에서 해결 (현재는 foreground 한정)
- **사용자 정의 스누즈 간격**: 일단 10분 고정. 설정 화면에서 5/10/30분 선택 옵션은 후속.
- **무한 스누즈 방지**: OS는 알아서 관리하지만, 우리도 같은 슬롯 스누즈 횟수를 IntakeLog.memo에 누적 기록 가능 (선택).

## 8. 작업 분량 추정

- 코드: ~80줄 (manager API + handler 분기 + cancel 확장)
- 테스트: 수동 5분 × 4 시나리오
- 총 소요: 1시간 이내
