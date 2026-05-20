import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'notification_action_handler.dart';
import 'notification_channels.dart';

/// 알림 인프라 초기화 + 채널 등록 + 권한 요청.
///
/// 실제 스케줄링은 [AlarmScheduler]가 담당.
class NotificationService {
  NotificationService(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      final localName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localName));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('local tz fallback: $e');
      }
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          NotificationChannels.actionCategory,
          actions: [
            DarwinNotificationAction.plain(
              NotificationChannels.actionTaken,
              '복용 완료',
              // foreground 옵션 제거 → 앱을 열지 않고 백그라운드 isolate에서
              // BackgroundActionDispatcher가 IntakeLog를 즉시 taken으로 기록.
            ),
            DarwinNotificationAction.plain(
              NotificationChannels.actionSnooze,
              '10분 후',
            ),
            DarwinNotificationAction.plain(
              NotificationChannels.actionSkip,
              '건너뜀',
              options: {DarwinNotificationActionOption.destructive},
            ),
          ],
        ),
      ],
    );

    await _plugin.initialize(
      InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: handleNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          handleBackgroundNotificationResponse,
    );

    await _registerAndroidChannels();
    _initialized = true;
  }

  Future<void> _registerAndroidChannels() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        NotificationChannels.reminderId,
        NotificationChannels.reminderName,
        description: NotificationChannels.reminderDescription,
        importance: Importance.high,
      ),
    );
    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        NotificationChannels.onTimeId,
        NotificationChannels.onTimeName,
        description: NotificationChannels.onTimeDescription,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ),
    );
    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        NotificationChannels.urgentId,
        NotificationChannels.urgentName,
        description: NotificationChannels.urgentDescription,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        // 전체화면 인텐트로 잠금화면에서 즉시 띄움 (긴급)
      ),
    );
  }

  FlutterLocalNotificationsPlugin get plugin => _plugin;

  Future<bool> requestPermissions() async {
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final iosGranted = await ios?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
          critical: false, // critical alerts: Apple 별도 승인 필요
        ) ??
        true;

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final androidGranted =
        await android?.requestNotificationsPermission() ?? true;
    final exactAlarm =
        await android?.requestExactAlarmsPermission() ?? true;

    return iosGranted && androidGranted && exactAlarm;
  }

  // 콜백은 notification_action_handler.dart의 top-level 함수로 이전.
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(FlutterLocalNotificationsPlugin());
});
