import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/medication/data/intake_providers.dart';
import 'background_actions.dart';
import 'notification_channels.dart';

/// 백그라운드 isolate에서 큐에 적재된 액션/스누즈를 main isolate에서 flush.
///
/// 앱 부팅 시 한 번 호출. 처리 성공한 항목만 큐에서 제거.
class PendingActionFlusher {
  PendingActionFlusher(this._container);

  final ProviderContainer _container;

  Future<void> flushAll() async {
    try {
      await _flushActions();
      await _flushSnoozes();
    } catch (e, st) {
      debugPrint('PendingActionFlusher.flushAll fail: $e\n$st');
    }
  }

  Future<void> _flushActions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(BackgroundActionDispatcher.prefsKeyPendingActions);
    if (raw == null || raw.isEmpty) return;

    final repo = _container.read(intakeRepositoryProvider);
    final remaining = <String>[];

    for (final entry in raw) {
      final decoded = BackgroundActionDispatcher.decodeAction(entry);
      if (decoded == null) continue;
      try {
        switch (decoded.actionId) {
          case NotificationChannels.actionTaken:
            await repo.markTaken(
              medicationId: decoded.payload.medicationId,
              scheduleId: decoded.payload.scheduleId,
              scheduledAt: decoded.payload.scheduledAt,
            );
            break;
          case NotificationChannels.actionSkip:
            await repo.markSkipped(
              medicationId: decoded.payload.medicationId,
              scheduleId: decoded.payload.scheduleId,
              scheduledAt: decoded.payload.scheduledAt,
            );
            break;
          default:
            // 알 수 없는 액션은 그냥 drop.
            break;
        }
      } catch (e) {
        debugPrint('flush action retry later: $e');
        remaining.add(entry);
      }
    }
    await prefs.setStringList(
      BackgroundActionDispatcher.prefsKeyPendingActions,
      remaining,
    );
  }

  Future<void> _flushSnoozes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(BackgroundActionDispatcher.prefsKeyPendingSnoozes);
    if (raw == null || raw.isEmpty) return;

    final remaining = <String>[];
    // 스누즈를 등록하려면 MedicationNotificationManager가 필요.
    // PR 01(snooze)이 머지된 후에만 실 등록 가능 — 이 PR에서는 큐만 비우고 로그.
    for (final entry in raw) {
      final decoded = BackgroundActionDispatcher.decodeSnooze(entry);
      if (decoded == null) continue;
      debugPrint(
        'flush snooze (TODO once snooze API merged): '
        'sched=${decoded.scheduleId} med=${decoded.medicationId}',
      );
    }
    // 일단 비움 (PR 01과 머지 후 실 등록 로직 추가 예정).
    await prefs.setStringList(
      BackgroundActionDispatcher.prefsKeyPendingSnoozes,
      remaining,
    );
  }
}

// 의도적으로 provider 미노출 — container를 직접 받아야 하므로 main.dart에서 인스턴스화.
