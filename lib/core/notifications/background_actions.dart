import 'dart:ui' show DartPluginRegistrant;

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart';
import '../database/tables/intake_logs.dart';
import 'notification_action_handler.dart' show DosePayload, parseDosePayload;
import 'notification_channels.dart';

/// 백그라운드 isolate 전용 액션 처리.
///
/// `flutter_local_notifications`의 `onDidReceiveBackgroundNotificationResponse`는
/// 별도 isolate에서 실행되어 main isolate의 `ProviderContainer`/싱글톤이 모두
/// 접근 불가. 여기서는 최소 의존성(`AppDatabase`, `SharedPreferences`)으로
/// 즉시 DB write를 시도하고, 실패하면 SharedPreferences 큐에 적재해 다음 앱
/// 실행 시 flush.
class BackgroundActionDispatcher {
  BackgroundActionDispatcher._();

  static const String prefsKeyPendingActions = 'pending_actions_v1';
  static const String prefsKeyPendingSnoozes = 'pending_snoozes_v1';

  /// 백그라운드 isolate 진입점에서 호출. 모든 실패는 큐로 흘림.
  static Future<void> dispatch(NotificationResponse response) async {
    // 새 isolate라 plugin registrant 미초기화. shared_preferences/path_provider
    // 등 method channel 사용 plugin을 쓰려면 ensureInitialized 필요.
    try {
      DartPluginRegistrant.ensureInitialized();
    } catch (e) {
      debugPrint('DartPluginRegistrant init fail: $e');
    }

    final payload = parseDosePayload(response.payload);
    if (payload == null) return;

    AppDatabase? db;
    try {
      switch (response.actionId) {
        case NotificationChannels.actionTaken:
          db = AppDatabase();
          await _markStatus(db, payload, IntakeStatus.taken);
          break;
        case NotificationChannels.actionSkip:
          db = AppDatabase();
          await _markStatus(db, payload, IntakeStatus.skipped);
          break;
        case NotificationChannels.actionSnooze:
          // 백그라운드 isolate에서 새 알림 등록은 plugin/timezone init 부담 큼.
          // 큐에 적재 후 다음 부팅에서 처리.
          await _enqueueSnooze(payload);
          break;
        default:
          // 본문 탭 → OS가 앱 foreground로 깨움 → 별도 처리 불필요.
          break;
      }
    } catch (e, st) {
      debugPrint('bg dispatch fail: $e\n$st');
      await _enqueueFailed(response);
    } finally {
      await db?.close();
    }
  }

  // -------------------------------------------------------------------------
  // DB upsert (IntakeRepository.mark과 동일 로직 inline — main isolate 의존 회피)
  // -------------------------------------------------------------------------

  static Future<void> _markStatus(
    AppDatabase db,
    DosePayload p,
    IntakeStatus status,
  ) async {
    final existing = await (db.select(db.intakeLogs)
          ..where((l) =>
              l.scheduleId.equals(p.scheduleId) &
              l.scheduledAt.equals(p.scheduledAt)))
        .getSingleOrNull();
    final now = DateTime.now();
    if (existing == null) {
      await db.into(db.intakeLogs).insert(
            IntakeLogsCompanion.insert(
              medicationId: Value(p.medicationId),
              scheduleId: Value(p.scheduleId),
              scheduledAt: p.scheduledAt,
              status: Value(status),
              actedAt: Value(now),
            ),
          );
    } else {
      await (db.update(db.intakeLogs)
            ..where((l) => l.id.equals(existing.id)))
          .write(IntakeLogsCompanion(
        status: Value(status),
        actedAt: Value(now),
        updatedAt: Value(now),
      ));
    }
  }

  // -------------------------------------------------------------------------
  // 큐 적재 (실패 fallback 또는 main isolate 위임용)
  // -------------------------------------------------------------------------

  static Future<void> _enqueueSnooze(DosePayload p) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(prefsKeyPendingSnoozes) ?? <String>[];
    raw.add(_encodeSnooze(p));
    await prefs.setStringList(prefsKeyPendingSnoozes, raw);
  }

  static Future<void> _enqueueFailed(NotificationResponse r) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(prefsKeyPendingActions) ?? <String>[];
      raw.add('${r.actionId ?? ""}|${r.payload ?? ""}');
      await prefs.setStringList(prefsKeyPendingActions, raw);
    } catch (e) {
      debugPrint('enqueueFailed itself failed: $e');
    }
  }

  static String _encodeSnooze(DosePayload p) {
    return '${p.scheduleId}|${p.medicationId}|${p.scheduledAt.toIso8601String()}';
  }

  /// 큐 항목 디코딩 (main isolate flush에서 사용).
  static ({int scheduleId, int medicationId, DateTime scheduledAt})?
      decodeSnooze(String raw) {
    final parts = raw.split('|');
    if (parts.length != 3) return null;
    try {
      return (
        scheduleId: int.parse(parts[0]),
        medicationId: int.parse(parts[1]),
        scheduledAt: DateTime.parse(parts[2]),
      );
    } catch (_) {
      return null;
    }
  }

  static ({String actionId, DosePayload payload})? decodeAction(String raw) {
    final pipeIdx = raw.indexOf('|');
    if (pipeIdx < 0) return null;
    final actionId = raw.substring(0, pipeIdx);
    final payload = parseDosePayload(raw.substring(pipeIdx + 1));
    if (payload == null) return null;
    return (actionId: actionId, payload: payload);
  }
}
