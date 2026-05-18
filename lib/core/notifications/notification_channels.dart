/// 알림 채널 / 카테고리 식별자 모음
class NotificationChannels {
  const NotificationChannels._();

  /// 사전 알람 (N분 전)
  static const String reminderId = 'pm_reminder';
  static const String reminderName = '복용 사전 알림';
  static const String reminderDescription = '복용 시각 N분 전에 미리 알려줍니다.';

  /// 정시 알람
  static const String onTimeId = 'pm_on_time';
  static const String onTimeName = '복용 시각 알림';
  static const String onTimeDescription = '정확한 복용 시각에 알려줍니다.';

  /// 미복용 긴급 반복 알람
  static const String urgentId = 'pm_urgent';
  static const String urgentName = '미복용 긴급 알림';
  static const String urgentDescription =
      '복용 시각이 지났는데 체크하지 않으면 큰 소리/진동으로 반복 알립니다.';

  /// iOS / Android 공통 액션 카테고리
  static const String actionCategory = 'pm_intake_actions';

  /// 액션 ID
  static const String actionTaken = 'action_taken';
  static const String actionSnooze = 'action_snooze';
  static const String actionSkip = 'action_skip';
}
