import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/notifications/medication_notification_manager.dart';
import 'core/notifications/notification_action_handler.dart';
import 'core/notifications/notification_service.dart';
import 'core/notifications/pending_action_flusher.dart';
import 'core/router/app_router.dart';
import 'core/storage/onboarding_storage.dart';
import 'features/medication/data/medication_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('ko');
  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
  );

  // 알림 액션 핸들러를 글로벌 hook에 등록 (foreground 콜백용).
  registerGlobalActionHandler(NotificationActionHandler(container));

  // 알림 인프라 초기화. launch details 조회는 init 직후여야 정확 → await 분기.
  // 초기화 완료 후:
  //  1) cold-start deep link 추출 (있으면 runApp에 전달)
  //  2) 백그라운드 isolate에서 큐에 적재된 pending 액션 flush
  //  3) DB 기반 스케줄을 시스템 알림에 동기화 (앱 재설치/업데이트 대비)
  await container.read(notificationServiceProvider).init();
  final pendingDeepLink = await _resolveColdStartDeepLink(container);
  unawaited(() async {
    await PendingActionFlusher(container).flushAll();
    // legacy 중복 schedules 정리 (same medicationId + timeOfDay)
    // — syncAll 보다 먼저 해서 정리된 schedules로 알림 동기화.
    final repo = container.read(trackedMedicationRepositoryProvider);
    await repo.cleanupDuplicateSchedules();
    await container.read(medicationNotificationManagerProvider).syncAll();
    // 과거 dedupe 도입 전 누적된 user catalog 중복 / relink 부산물 정리.
    await repo.cleanupOrphanUserCatalogs();
  }());

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: PillMateApp(pendingDeepLink: pendingDeepLink),
    ),
  );
}

/// 알림으로 cold start된 경우 deep link 경로 추출. 없으면 null.
Future<String?> _resolveColdStartDeepLink(ProviderContainer container) async {
  try {
    final launch = await container
        .read(notificationServiceProvider)
        .plugin
        .getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp != true) return null;
    final payload = parseDosePayload(launch?.notificationResponse?.payload);
    if (payload == null) return null;
    return '${AppRoute.drawer}/${payload.medicationId}';
  } catch (_) {
    return null;
  }
}
