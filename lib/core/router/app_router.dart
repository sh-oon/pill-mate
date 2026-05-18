import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/presentation/home_screen.dart';
import '../../features/medication/presentation/medication_form_screen.dart';
import '../../features/medication/presentation/medication_list_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';

class AppRoute {
  const AppRoute._();
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const home = '/';
  static const medications = '/medications';
  static const medicationNew = '/medications/new';
  static const medicationEdit = '/medications/:id/edit';
  static const settings = '/settings';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoute.splash,
    routes: [
      GoRoute(
        path: AppRoute.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoute.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoute.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoute.medications,
        builder: (context, state) => const MedicationListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) =>
                const MedicationFormScreen(medicationId: null),
          ),
          GoRoute(
            path: ':id/edit',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '');
              return MedicationFormScreen(medicationId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRoute.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('오류')),
      body: Center(child: Text('경로를 찾을 수 없습니다: ${state.uri}')),
    ),
  );
});
