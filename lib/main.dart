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
import 'core/storage/onboarding_storage.dart';

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

  // 알림 인프라는 백그라운드에서 초기화 (스플래시 노출 지연 방지).
  // 초기화 완료 후:
  //  1) 백그라운드 isolate에서 큐에 적재된 pending 액션 flush
  //  2) DB 기반 스케줄을 시스템 알림에 동기화 (앱 재설치/업데이트 대비)
  unawaited(() async {
    await container.read(notificationServiceProvider).init();
    await PendingActionFlusher(container).flushAll();
    await container.read(medicationNotificationManagerProvider).syncAll();
  }());

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const PillMateApp(),
    ),
  );
}
