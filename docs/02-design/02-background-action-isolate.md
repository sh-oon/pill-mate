---
template: design
version: 1.0
feature: phase-4-background-isolate
date: 2026-05-19
author: gamja
project: pill-mate
platform: Flutter (iOS + Android)
status: Draft
---

# 02 — 백그라운드 isolate에서 알림 액션 처리

> **Summary**: 앱이 떠있지 않을 때 사용자가 알림에서 액션(복용 완료 / 건너뜀 / 스누즈)을 누르면 즉시 DB에 반영되도록 백그라운드 isolate에서 동작하는 액션 핸들러를 구현. 현재는 로깅만 됨.

## 1. 문제 / Why

### 현재 동작
- `handleBackgroundNotificationResponse`는 별도 isolate에서 호출됨 → `_globalHandler == null`
- foreground(앱 열려있을 때) 액션만 동작
- 백그라운드 액션은 데이터 유실 — 사용자가 알림에서 "복용 완료" 눌러도 다음에 앱 열면 missed로 표시됨

### 사용자 가치
- 알림 → 액션 → 즉시 반영이 본질. 안 그러면 알림 액션 자체가 무의미
- 사용자가 액션 후 1시간 뒤에 앱 열어도 그때까지 잘못된 카운트/상태 노출

## 2. 제약

- 백그라운드 isolate는 main isolate와 메모리 공유 안 됨 — Flutter `ProviderContainer`/`Singleton`/`InheritedWidget` 일체 사용 불가
- Dart `@pragma('vm:entry-point')` 필수 — top-level 함수만 가능
- Drift `AppDatabase`는 isolate-safe하지만 새 인스턴스를 생성/닫는 비용 있음
- 새 isolate에서 모든 plugin이 초기화되지는 않음 — `flutter_local_notifications`는 OK이지만 `path_provider`도 별도 init 필요할 수 있음

## 3. 접근

### 옵션 비교

| 옵션 | 설명 | 평가 |
|---|---|---|
| **A. 즉시 처리 (새 ProviderContainer)** | 백그라운드 콜백 안에서 새 `ProviderContainer` + `AppDatabase` 생성 → 즉시 DB write → close | **채택** (1차) — 즉시 반영, 코드 복잡도 중 |
| B. 큐잉 + 다음 앱 실행 시 flush | `SharedPreferences`에 액션 페이로드 큐 저장 → 앱 부팅 시 처리 | 백업 안전망으로만 (A 실패 시) |
| C. Workmanager / background fetch | 더 무거운 백그라운드 API. 짧은 콜백에는 과함 | 폐기 |

### 하이브리드 채택
- **주 경로 = A**: 백그라운드 콜백에서 즉시 DB write 시도
- **백업 경로 = B**: 실패하거나 plugin 초기화 안 되면 SharedPreferences에 페이로드 push → 다음 앱 부팅 시 flush

### 새 isolate에서 필요한 최소 의존성

```
백그라운드 핸들러
 ├─ AppDatabase (Drift) — DB write
 ├─ FlutterLocalNotificationsPlugin — 스누즈 시 새 알림 등록
 └─ shared_preferences — 백업 큐 (필요 시)
```

UI/Router/Riverpod observers 등은 일체 import 안 함.

## 4. 구현 계획

### Step 1. `background_actions.dart` 신규 — 백그라운드 전용 헬퍼

```dart
// lib/core/notifications/background_actions.dart

import 'package:drift/native.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart';

/// 백그라운드 isolate 전용 — 최소 의존성으로 액션 처리.
class BackgroundActionDispatcher {
  /// 백그라운드 isolate에서 안전하게 호출 가능.
  static Future<void> dispatch(NotificationResponse response) async {
    final payload = parseDosePayload(response.payload);
    if (payload == null) return;

    AppDatabase? db;
    try {
      db = await _openDb();
      switch (response.actionId) {
        case NotificationChannels.actionTaken:
          await _markStatus(db, payload, IntakeStatus.taken);
          break;
        case NotificationChannels.actionSkip:
          await _markStatus(db, payload, IntakeStatus.skipped);
          break;
        case NotificationChannels.actionSnooze:
          await _enqueueSnoozeForLater(payload);
          break;
      }
    } catch (e) {
      // 백업: SharedPreferences 큐에 적재.
      await _enqueueFailed(response);
    } finally {
      await db?.close();
    }
  }

  static Future<AppDatabase> _openDb() async {
    final dir = await getApplicationSupportDirectory();
    // AppDatabase에 file-based 생성자 추가 필요 (Step 3 참조)
    return AppDatabase.forBackground(dir);
  }

  static Future<void> _markStatus(
    AppDatabase db,
    DosePayload p,
    IntakeStatus status,
  ) async {
    // IntakeRepository의 mark()와 동일 로직을 인라인.
    // (Repository를 그대로 쓰려면 추가 의존이 늘어남)
  }

  static Future<void> _enqueueSnoozeForLater(DosePayload p) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('pending_snoozes') ?? [];
    raw.add('${p.scheduleId}:${p.medicationId}:${p.scheduledAt.toIso8601String()}');
    await prefs.setStringList('pending_snoozes', raw);
  }

  static Future<void> _enqueueFailed(NotificationResponse r) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('pending_actions') ?? [];
    raw.add('${r.actionId ?? ""}|${r.payload ?? ""}');
    await prefs.setStringList('pending_actions', raw);
  }
}
```

### Step 2. `handleBackgroundNotificationResponse` 교체

```dart
@pragma('vm:entry-point')
void handleBackgroundNotificationResponse(NotificationResponse response) {
  // top-level이라 await 불가, fire-and-forget.
  BackgroundActionDispatcher.dispatch(response);
}
```

### Step 3. `AppDatabase`에 background 전용 factory 추가

```dart
AppDatabase.forBackground(Directory dir)
    : super(NativeDatabase.createInBackground(
        File(p.join(dir.path, 'pill_mate.sqlite')),
      ));
```

- 기존 `driftDatabase()` 헬퍼는 isolate-safe하지만 별도 검증 필요
- file path는 main isolate가 쓰는 것과 정확히 같아야 함 (path_provider 결과 동일)

### Step 4. 앱 부팅 시 큐 flush

`main.dart`의 `syncAll()` 직전에:

```dart
await container.read(intakeRepositoryProvider).flushBackgroundQueues();
```

`IntakeRepository.flushBackgroundQueues()`:
1. `pending_actions` 큐를 읽어 각각 payload 파싱 후 markTaken/markSkipped 적용
2. `pending_snoozes` 큐를 읽어 각각 scheduleSnooze 적용 (단, 이미 너무 늦었으면 skip)
3. 처리 완료된 항목은 SharedPreferences에서 제거

### Step 5. iOS 측 확인

iOS는 `onDidReceiveBackgroundNotificationResponse`가 호출되려면:
- `Info.plist`에 `UIBackgroundModes` → `remote-notification` 필요 (이미 있음 ✓)
- 로컬 알림 액션이 `foreground` 옵션 없을 때 → 백그라운드 호출

현재 iOS 액션 설정 (`notification_service.dart`):
- "복용 완료" → `foreground` 옵션 있음 → 앱이 켜짐 → foreground 핸들러 호출됨 (OK)
- "10분 후" / "건너뜀" → foreground 옵션 없음 → 백그라운드 핸들러 호출됨 (이 문서 적용 대상)

## 5. 데이터/스키마 변경

- `AppDatabase`에 background factory 추가 (코드만, 스키마 변경 없음)
- SharedPreferences 키 신규: `pending_actions`, `pending_snoozes`

## 6. 테스트 계획

| # | 시나리오 | 기대 |
|---|---|---|
| T1 | 앱 종료 상태 → 알림 도착 → "건너뜀" 액션 | 다음 앱 실행 시 해당 슬롯 IntakeLog `status=skipped` 이미 기록됨 |
| T2 | 앱 종료 상태 → "10분 후" 액션 | 10분 뒤 스누즈 알림 도착 (즉시 등록 실패 시 다음 부팅 후 catch-up) |
| T3 | 백그라운드 DB 열기 실패 시뮬 (path_provider 에러) | `pending_actions` 큐에 적재 → 다음 부팅에서 처리 |
| T4 | 큐 처리 중 일부 실패 | 실패한 항목만 큐에 남고 성공한 것은 제거 |
| T5 | 같은 액션 중복 적재 (네트워크/OS 이슈) | idempotent: 같은 (scheduleId, scheduledAt)에 두 번 markTaken 호출되어도 결과 동일 |

## 7. 위험 / Out of scope

- **iOS 시뮬레이터 한계**: 시뮬레이터의 백그라운드 isolate 동작이 실기기와 다름. 실기기 검증 필요.
- **path_provider 백그라운드 init**: 일부 OS 버전에서 첫 호출이 실패할 수 있음. 백업 큐가 안전망.
- **Drift isolate 동시성**: main isolate가 DB를 열고 있는 동안 background isolate가 또 열면 SQLite WAL 모드가 잘 동작해야 함. 표준 SQLite는 multi-reader, single-writer이므로 동시 write 직렬화는 OS 레벨에서 처리됨.
- **스누즈 일회성 알림 등록 in background**: 이론상 가능. 실패하면 큐로 fallback.
- **알림 본문 탭의 deep link**: 04 문서 범위.

## 8. 작업 분량 추정

- 코드: ~250줄 (background dispatcher + DB factory + 큐 flush)
- 테스트: 실기기 30분
- 총 소요: 2~3시간
