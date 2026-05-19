import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/medication/data/intake_providers.dart';
import 'background_actions.dart';
import 'notification_channels.dart';

/// 알림 payload 파싱 결과 — `dose:scheduleId:medicationId:isoScheduledAt`.
///
/// 백그라운드 isolate에서도 import 가능하도록 top-level public.
class DosePayload {
  const DosePayload({
    required this.scheduleId,
    required this.medicationId,
    required this.scheduledAt,
  });

  final int scheduleId;
  final int medicationId;
  final DateTime scheduledAt;
}

/// 알림 payload 문자열 파싱. 잘못된 형식이면 null.
DosePayload? parseDosePayload(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final parts = raw.split(':');
  if (parts.length < 4 || parts.first != 'dose') return null;
  try {
    // ISO 8601 문자열에 ':' 포함. parts[3..end] 모두 합쳐서 파싱.
    final iso = parts.sublist(3).join(':');
    return DosePayload(
      scheduleId: int.parse(parts[1]),
      medicationId: int.parse(parts[2]),
      scheduledAt: DateTime.parse(iso),
    );
  } catch (e) {
    debugPrint('payload parse fail: $raw — $e');
    return null;
  }
}

/// 알림 액션 (복용 완료 / 스누즈 / 건너뜀)을 Riverpod 컨테이너 위에서 처리.
///
/// `flutter_local_notifications`의 콜백은 top-level/static 이어야 하므로,
/// 모듈 전역 `_globalHandler`를 통해 인스턴스에 접근한다.
class NotificationActionHandler {
  NotificationActionHandler(this._container);

  final ProviderContainer _container;

  Future<void> handle(NotificationResponse response) async {
    final payload = parseDosePayload(response.payload);
    if (payload == null) {
      debugPrint('skip notification — no/invalid payload');
      return;
    }

    final repo = _container.read(intakeRepositoryProvider);

    switch (response.actionId) {
      case NotificationChannels.actionTaken:
        await repo.markTaken(
          medicationId: payload.medicationId,
          scheduleId: payload.scheduleId,
          scheduledAt: payload.scheduledAt,
        );
        break;
      case NotificationChannels.actionSkip:
        await repo.markSkipped(
          medicationId: payload.medicationId,
          scheduleId: payload.scheduleId,
          scheduledAt: payload.scheduledAt,
        );
        break;
      case NotificationChannels.actionSnooze:
        // TODO: 10분 뒤 일회성 알림 등록 — 별도 헬퍼 필요.
        debugPrint('snooze (TODO 10min one-shot): ${payload.scheduleId}');
        break;
      default:
        // 액션 없이 알림 본문 탭한 경우 → 앱 열기 (router 진입 처리는 별도).
        debugPrint('notification tapped (no action): ${response.payload}');
    }
  }
}

// =============================================================================
// 글로벌 hook — flutter_local_notifications 콜백이 top-level 이어야 함.
// =============================================================================

NotificationActionHandler? _globalHandler;

void registerGlobalActionHandler(NotificationActionHandler handler) {
  _globalHandler = handler;
}

/// Foreground 콜백.
void handleNotificationResponse(NotificationResponse response) {
  _globalHandler?.handle(response);
}

/// Background isolate 콜백 — 새 isolate에서 실행되므로 _globalHandler가 null.
/// 새 ProviderContainer 없이 최소 의존성(AppDatabase, SharedPreferences)으로
/// BackgroundActionDispatcher가 즉시 처리. 실패 시 SharedPreferences 큐에
/// 적재되어 다음 앱 부팅 시 flush.
@pragma('vm:entry-point')
void handleBackgroundNotificationResponse(NotificationResponse response) {
  // top-level fire-and-forget. await 불가.
  BackgroundActionDispatcher.dispatch(response);
}
