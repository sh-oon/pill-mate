---
template: design
version: 1.0
feature: phase-4-deep-link
date: 2026-05-19
author: gamja
project: pill-mate
platform: Flutter (iOS + Android)
status: Draft
---

# 04 — 알림 본문 탭 → 약 상세 deep link

> **Summary**: 알림 액션이 아니라 본문(notification body)을 탭하면 앱이 열리면서 해당 약의 상세 화면(`/drawer/:id`)으로 자동 이동. 알림이 단순 reminder 이상의 진입점이 되어 사용자가 같은 약을 검색해 들어가는 마찰을 제거.

## 1. 문제 / Why

### 현재 동작
- 사용자가 알림 본문 탭 → 앱 열림 → 항상 홈 (or 마지막 화면)
- 어느 약인지 다시 찾아 약 서랍 → 카드 탭 해야 상세 접근

### 사용자 가치
- 알림 → 상세 진입 1회 탭으로 단축
- 메모/시간/스케줄을 즉시 확인 가능
- 상세에서 바로 "수정" 또는 알람 토글 등 후속 액션

## 2. 제약

- foreground와 background 진입 두 경로 모두 처리
- 앱 cold start 진입 시: `getNotificationAppLaunchDetails()`로 launch payload 조회 가능
- 앱 warm resume 진입 시: `onDidReceiveNotificationResponse` 콜백
- go_router는 `initialLocation` 또는 runtime `context.go()` 둘 다 사용 가능

## 3. 접근

### 옵션 비교

| 옵션 | 설명 | 평가 |
|---|---|---|
| **A. 글로벌 라우터 참조 + actionId null 분기** | 액션 없이 본문 탭 = `response.actionId == null`. 글로벌 `GoRouter` 인스턴스로 `router.push('/drawer/:id')` | **채택** — 가장 직접적 |
| B. Pending intent 큐 + 홈 화면에서 consume | 페이로드 저장 → 홈에서 한 번만 라우팅 | 우회 패턴, 코드 늘어남 |
| C. iOS Universal Link / Android App Link | 외부 링크 → 앱 진입. local notification 컨텍스트에선 과함 | 폐기 (push 알림 도입 시 검토) |

### A 채택 — 두 진입 경로 통합

```
앱 cold start:
  splash → checkLaunchDetails() → 페이로드 있으면 onboarding/홈 분기 후 / 약 상세 push

앱 warm resume:
  onDidReceiveNotificationResponse (actionId == null)
  → globalRouter.push('/drawer/:id')
```

## 4. 구현 계획

### Step 1. 글로벌 라우터 참조 노출

`app_router.dart`에 navigator key 이미 있음. provider 외에 글로벌 변수 추가:

```dart
final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

// 알림 액션 핸들러에서 접근하는 글로벌 참조 (main isolate 한정).
GoRouter? globalRouter;

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: _rootKey,
    ...
  );
  globalRouter = router;
  return router;
});
```

또는 더 깔끔: 별도 `core/navigation/global_router.dart`에 `static` 보관.

### Step 2. `NotificationActionHandler` 본문 탭 분기

```dart
switch (response.actionId) {
  case NotificationChannels.actionTaken: ...
  case NotificationChannels.actionSkip: ...
  case NotificationChannels.actionSnooze: ...
  default:
    // 본문 탭 (actionId == null)
    _routeToDetail(payload.medicationId);
}

void _routeToDetail(int medId) {
  final r = globalRouter;
  if (r == null) return; // 라우터 아직 준비 안 됨
  r.push('/drawer/$medId');
}
```

### Step 3. Cold start 처리 — `main.dart`에서 launch details 조회

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // ... 기존 init ...

  // 알림으로 cold start된 경우 페이로드 수집.
  final launch = await container
      .read(notificationServiceProvider)
      .plugin
      .getNotificationAppLaunchDetails();
  String? pendingRoute;
  if (launch?.didNotificationLaunchApp == true) {
    final payload = launch?.notificationResponse?.payload;
    final parsed = parseDosePayload(payload);
    if (parsed != null) {
      pendingRoute = '/drawer/${parsed.medicationId}';
    }
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: PillMateApp(pendingRoute: pendingRoute),
    ),
  );
}
```

### Step 4. `PillMateApp`에 `pendingRoute` 처리

```dart
class PillMateApp extends ConsumerStatefulWidget {
  const PillMateApp({super.key, this.pendingRoute});
  final String? pendingRoute;
  ...
}

class _PillMateAppState extends ConsumerState<PillMateApp> {
  @override
  void initState() {
    super.initState();
    final route = widget.pendingRoute;
    if (route != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final router = ref.read(appRouterProvider);
        // splash 마치고 home으로 분기된 직후 push되도록 1.5초 지연.
        Future.delayed(const Duration(milliseconds: 1500),
            () => router.push(route));
      });
    }
  }
  ...
}
```

splash + onboarding 완료 후 라우팅돼야 자연스러움. 단순 delay 또는 splash 완료 신호를 통한 await 둘 다 가능. delay가 단순.

### Step 5. 백그라운드 isolate에서는?

- 백그라운드 콜백에서 본문 탭은 보통 OS가 앱을 foreground로 깨움 → foreground 핸들러로 진입
- 02 문서의 background dispatcher는 액션 처리만 담당, 본문 탭은 자연스럽게 foreground로 흐름
- 별도 처리 불필요

### Step 6. 페이로드가 없거나 약이 이미 삭제됨

- `globalRouter.push('/drawer/$medId')` → 상세 화면이 `medicationByIdProvider`에서 null 받으면 "이미 삭제된 약" fallback (이미 구현됨 ✓)

## 5. 데이터/스키마 변경

- 없음

## 6. 테스트 계획

| # | 시나리오 | 기대 |
|---|---|---|
| T1 | 앱 종료 → 알림 도착 → 본문 탭 (액션 X) | 앱 cold start → splash 짧게 → 약 상세 화면 자동 진입 |
| T2 | 앱 백그라운드 → 본문 탭 | 앱 foreground 복귀 + 즉시 약 상세 push |
| T3 | 앱 foreground (홈 화면) → 알림 도착 → 본문 탭 | 약 상세 push |
| T4 | 알림에서 액션 "복용 완료" 탭 (본문 X) | 액션 처리만, 라우팅 안 됨 |
| T5 | 알림 페이로드의 약이 이미 삭제됨 | 상세 화면 "이미 삭제된 약" fallback |
| T6 | 알림 페이로드 형식 오류 | 라우팅 안 함, 로그만 |

## 7. 위험 / Out of scope

- **두 번 push 방지**: cold start의 pendingRoute가 처리되기 전에 사용자가 다시 알림 탭하면 중복 push 가능. `usedOnce` 플래그로 가드.
- **splash 도중 라우팅**: splash가 onboarding/home으로 가는 동안 deep link push가 먼저 끼어들면 navigation stack이 꼬일 수 있음. delay 또는 splash 완료 후 trigger로 안전화.
- **인앱 알림(스낵바/시트) 충돌**: 알림 도착 시 인앱에서도 별도 UI 띄우는 경우 라우팅 우선순위 결정 필요. v1에서는 라우팅만.
- **다른 진입점 deep link**: 캘린더 특정 일자, 리포트 등은 별도 패턴. 이 문서 범위 밖.

## 8. 작업 분량 추정

- 코드: ~120줄 (글로벌 router + handler 분기 + cold start + delay)
- 테스트: 30분 × 3 경로 (cold/warm/foreground)
- 총 소요: 1.5~2시간
