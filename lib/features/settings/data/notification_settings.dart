import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/onboarding_storage.dart';

/// 사용자 조절 가능한 알림 옵션. 현재는 스누즈 간격만.
/// 약별 "사전 알림 분"은 schedules.remindBeforeMinutes 컬럼이라 별개.
class NotificationSettings {
  const NotificationSettings({this.snoozeMinutes = 10});

  final int snoozeMinutes;

  NotificationSettings copyWith({int? snoozeMinutes}) =>
      NotificationSettings(snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes);
}

/// 사용자가 고를 수 있는 스누즈 간격(분).
const kSnoozeOptions = <int>[5, 10, 15, 30];

const _kSnoozeKey = 'pm.settings.snoozeMinutes.v1';

class NotificationSettingsNotifier extends Notifier<NotificationSettings> {
  @override
  NotificationSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final raw = prefs.getInt(_kSnoozeKey);
    final m = (raw != null && kSnoozeOptions.contains(raw)) ? raw : 10;
    return NotificationSettings(snoozeMinutes: m);
  }

  Future<void> setSnoozeMinutes(int minutes) async {
    final clamped =
        kSnoozeOptions.contains(minutes) ? minutes : 10;
    await ref.read(sharedPreferencesProvider).setInt(_kSnoozeKey, clamped);
    state = state.copyWith(snoozeMinutes: clamped);
  }
}

final notificationSettingsProvider =
    NotifierProvider<NotificationSettingsNotifier, NotificationSettings>(
  NotificationSettingsNotifier.new,
);
