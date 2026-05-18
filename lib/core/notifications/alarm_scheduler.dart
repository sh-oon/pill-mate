import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

import 'notification_channels.dart';
import 'notification_service.dart';

/// 한 복용 일정에 대한 3단계 알람 묶음을 예약/취소한다.
///
/// - reminder: 예정 시각 N분 전 (선택)
/// - onTime: 예정 시각 (필수)
/// - urgent: 예정 시각 +M분, +2M분, ... 미복용 동안 반복 (선택)
///
/// 알림 ID 규칙 (한 intakeLog 당 최대 1 + 1 + maxRepeats 개):
///   reminder = intakeLogId * 1000 + 0
///   onTime   = intakeLogId * 1000 + 1
///   urgent   = intakeLogId * 1000 + 100 + n  (n = 1..maxRepeats)
class AlarmScheduler {
  AlarmScheduler(this._service);

  final NotificationService _service;

  static const int _kReminderSlot = 0;
  static const int _kOnTimeSlot = 1;
  static const int _kUrgentSlotBase = 100;
  static const int defaultUrgentMaxRepeats = 6;

  FlutterLocalNotificationsPlugin get _plugin => _service.plugin;

  Future<void> scheduleIntake({
    required int intakeLogId,
    required String medicationName,
    required DateTime scheduledAt,
    int? remindBeforeMinutes,
    int? urgentRepeatMinutes,
    int? urgentMaxRepeats,
  }) async {
    final scheduledTz = tz.TZDateTime.from(scheduledAt, tz.local);

    if (remindBeforeMinutes != null && remindBeforeMinutes > 0) {
      final reminderAt =
          scheduledTz.subtract(Duration(minutes: remindBeforeMinutes));
      if (reminderAt.isAfter(tz.TZDateTime.now(tz.local))) {
        await _zonedSchedule(
          id: _idFor(intakeLogId, _kReminderSlot),
          when: reminderAt,
          title: '$medicationName 복용 $remindBeforeMinutes분 전',
          body: '곧 복용 시간입니다.',
          channelId: NotificationChannels.reminderId,
          channelName: NotificationChannels.reminderName,
          payload: 'intake:$intakeLogId:reminder',
          urgent: false,
        );
      }
    }

    await _zonedSchedule(
      id: _idFor(intakeLogId, _kOnTimeSlot),
      when: scheduledTz,
      title: '$medicationName 복용 시간',
      body: '복용 후 체크해주세요.',
      channelId: NotificationChannels.onTimeId,
      channelName: NotificationChannels.onTimeName,
      payload: 'intake:$intakeLogId:onTime',
      urgent: false,
    );

    if (urgentRepeatMinutes != null && urgentRepeatMinutes > 0) {
      final max = urgentMaxRepeats ?? defaultUrgentMaxRepeats;
      for (var n = 1; n <= max; n++) {
        final at = scheduledTz.add(Duration(minutes: urgentRepeatMinutes * n));
        await _zonedSchedule(
          id: _idFor(intakeLogId, _kUrgentSlotBase + n),
          when: at,
          title: '⚠️ $medicationName 미복용 알림',
          body: '아직 복용 체크가 되지 않았어요. 지금 확인해주세요.',
          channelId: NotificationChannels.urgentId,
          channelName: NotificationChannels.urgentName,
          payload: 'intake:$intakeLogId:urgent:$n',
          urgent: true,
        );
      }
    }
  }

  Future<void> cancelIntake(int intakeLogId, {int maxRepeats = 32}) async {
    await _plugin.cancel(_idFor(intakeLogId, _kReminderSlot));
    await _plugin.cancel(_idFor(intakeLogId, _kOnTimeSlot));
    for (var n = 1; n <= maxRepeats; n++) {
      await _plugin.cancel(_idFor(intakeLogId, _kUrgentSlotBase + n));
    }
  }

  /// 사용자가 복용 체크하면 남은 긴급 알람들을 모두 취소한다.
  Future<void> cancelUrgentTail(int intakeLogId, {int maxRepeats = 32}) async {
    for (var n = 1; n <= maxRepeats; n++) {
      await _plugin.cancel(_idFor(intakeLogId, _kUrgentSlotBase + n));
    }
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  Future<void> _zonedSchedule({
    required int id,
    required tz.TZDateTime when,
    required String title,
    required String body,
    required String channelId,
    required String channelName,
    required String payload,
    required bool urgent,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: urgent ? Importance.max : Importance.high,
      priority: urgent ? Priority.max : Priority.high,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: urgent,
      playSound: true,
      enableVibration: true,
      actions: const [
        AndroidNotificationAction(
          NotificationChannels.actionTaken,
          '복용 완료',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          NotificationChannels.actionSnooze,
          '10분 후',
          showsUserInterface: false,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          NotificationChannels.actionSkip,
          '건너뜀',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );
    const iosDetails = DarwinNotificationDetails(
      categoryIdentifier: NotificationChannels.actionCategory,
      interruptionLevel: InterruptionLevel.timeSensitive,
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      when,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  int _idFor(int intakeLogId, int slot) => intakeLogId * 1000 + slot;
}

final alarmSchedulerProvider = Provider<AlarmScheduler>((ref) {
  return AlarmScheduler(ref.watch(notificationServiceProvider));
});
