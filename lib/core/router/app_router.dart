import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/calendar/presentation/calendar_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/medication/presentation/add/medication_add_flow.dart';
import '../../features/medication/presentation/medication_detail_screen.dart';
import '../../features/medication/presentation/medication_list_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../mockups/mockups_index.dart';
import 'tab_shell.dart';

class AppRoute {
  const AppRoute._();
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const home = '/';
  static const drawer = '/drawer';
  static const drawerNew = '/drawer/new';
  static const drawerDetail = '/drawer/:id'; // 동적 (드로어 id)
  static const drawerEdit = '/drawer/:id/edit';

  /// 동적 detail 경로 helper.
  static String drawerDetailPath(int id) => '/drawer/$id';
  static const reports = '/reports';
  static const calendar = '/calendar';
  static const settings = '/settings';

  /// Phase 3 디자인 mockup 색인 (debug only — release build에서도 라우트는
  /// 등록되지만 진입로는 settings에서 kDebugMode일 때만 노출).
  static const mockups = '/mockups';
}

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// 알림 액션 콜백 등 Riverpod 컨텍스트 밖에서 router에 접근하기 위한 글로벌 참조.
/// main isolate에서만 set/use. (백그라운드 isolate 안 됨)
GoRouter? globalRouter;

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: AppRoute.splash,
    // CNTabBar의 모달/시트 z-order 협조용 옵저버.
    // 시트 위로 CNTabBar가 떠 보이는 문제 방지 + Liquid Glass halo 클램프.
    observers: [CNTabBarRouteObserver()],
    routes: [
      GoRoute(
        path: AppRoute.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoute.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      // 탭 외부 진입 (헤더 톱니 → 설정).
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: AppRoute.settings,
        builder: (context, state) => const SettingsScreen(),
      ),

      // Phase 3 디자인 mockup 색인 (dev only).
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: AppRoute.mockups,
        builder: (context, state) => const MockupsIndex(),
      ),

      // 4개 탭 셸.
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => TabShell(shell: shell),
        branches: [
          // 0: 홈
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          // 1: 약 서랍
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.drawer,
                builder: (context, state) => const MedicationListScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (context, state) => const MedicationAddFlow(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) {
                      final id = int.tryParse(
                              state.pathParameters['id'] ?? '') ??
                          1;
                      return MedicationDetailScreen(medicationId: id);
                    },
                    routes: [
                      GoRoute(
                        path: 'edit',
                        builder: (context, state) {
                          final id = int.tryParse(
                              state.pathParameters['id'] ?? '');
                          return MedicationAddFlow(medicationId: id);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // 2: 리포트
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.reports,
                builder: (context, state) => const ReportsScreen(),
              ),
            ],
          ),
          // 3: 캘린더
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.calendar,
                builder: (context, state) => const CalendarScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('오류')),
      body: Center(child: Text('경로를 찾을 수 없습니다: ${state.uri}')),
    ),
  );
  globalRouter = router;
  return router;
});
