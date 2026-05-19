import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

import '../database/app_database.dart';
import '../database/database_providers.dart';
import '../database/tables/schedules.dart';
import 'notification_channels.dart';
import 'notification_service.dart';

/// 약 단위 schedule 기반 반복 알림 매니저.
///
/// AlarmScheduler가 단발(per-intakeLog) 모델인 것과 달리, 여기는
/// schedule 단위 daily/weekly 반복 알림을 시스템에 동기화한다.
///
/// 알림 ID 규칙:
/// - daily: scheduleId 그대로
/// - weekly: scheduleId * 10 + dayOfWeekIndex(1..7, Mon=1..Sun=7)
class MedicationNotificationManager {
  MedicationNotificationManager(this._service, this._db);

  final NotificationService _service;
  final AppDatabase _db;

  FlutterLocalNotificationsPlugin get _plugin => _service.plugin;

  // ==========================================================================
  // Public API
  // ==========================================================================

  /// 한 약의 활성 schedule 전부를 시스템에 재반영.
  Future<void> syncSchedulesFor(int medicationId) async {
    final med = await (_db.select(_db.medications)
          ..where((m) => m.id.equals(medicationId)))
        .getSingleOrNull();
    if (med == null) {
      await cancelForMedication(medicationId);
      return;
    }

    await cancelForMedication(medicationId);
    if (med.archived) return;

    final scheds = await (_db.select(_db.schedules)
          ..where((s) =>
              s.medicationId.equals(medicationId) & s.enabled.equals(true)))
        .get();

    for (final s in scheds) {
      try {
        await _scheduleRecurring(med: med, schedule: s);
      } catch (e, st) {
        debugPrint('schedule fail med=${med.id} sched=${s.id}: $e\n$st');
      }
    }
  }

  /// 약 삭제/비활성 시 해당 약의 모든 알림 취소.
  Future<void> cancelForMedication(int medicationId) async {
    final scheds = await (_db.select(_db.schedules)
          ..where((s) => s.medicationId.equals(medicationId)))
        .get();
    for (final s in scheds) {
      await _cancelSchedule(s);
    }
  }

  /// 앱 부팅/업데이트 시 전체 재구성.
  Future<void> syncAll() async {
    await _plugin.cancelAll();
    final meds = await _db.select(_db.medications).get();
    for (final m in meds.where((x) => !x.archived)) {
      await syncSchedulesFor(m.id);
    }
  }

  // ==========================================================================
  // Internals
  // ==========================================================================

  Future<void> _scheduleRecurring({
    required Medication med,
    required Schedule schedule,
  }) async {
    switch (schedule.repeatKind) {
      case RepeatKind.daily:
        await _scheduleDaily(med, schedule);
        break;
      case RepeatKind.weekly:
        await _scheduleWeekly(med, schedule);
        break;
      case RepeatKind.interval:
        // N일 간격 반복은 OS 기본 매칭 컴포넌트로 표현 불가.
        // TODO: 다음 occurrence만 단발 등록 + 사용자 액션 후 재등록 흐름 필요.
        debugPrint('interval repeat not yet supported (sched=${schedule.id})');
        break;
    }
  }

  Future<void> _scheduleDaily(Medication med, Schedule s) async {
    final next = _nextOccurrence(s.timeOfDay);

    // 1) N분 전 사전 알림 (daily 반복).
    if ((s.remindBeforeMinutes ?? 0) > 0) {
      final preTime =
          _subtractMinutes(s.timeOfDay, s.remindBeforeMinutes!);
      final preNext = _nextOccurrence(preTime);
      await _plugin.zonedSchedule(
        _preReminderIdFor(s),
        '${med.name} 복용 ${s.remindBeforeMinutes}분 전',
        '곧 복용 시간입니다.',
        preNext,
        _details(NotifTone.reminder),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: _payload(s, next), // 원래 시각 그대로 (액션은 원슬롯)
      );
    }

    // 2) onTime — 본 알림.
    await _plugin.zonedSchedule(
      _dailyIdFor(s),
      '${med.name} 복용 시간',
      _quantityHint(med),
      next,
      _details(NotifTone.onTime),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // 매일 같은 시각 반복
      payload: _payload(s, next),
    );

    // 3) urgent 재알림 — 단발 K개 (오늘 분만).
    if ((s.urgentRepeatMinutes ?? 0) > 0) {
      final max = s.urgentMaxRepeats ?? defaultUrgentMaxRepeats;
      final now = tz.TZDateTime.now(tz.local);
      for (var n = 1; n <= max; n++) {
        final at = next.add(Duration(minutes: s.urgentRepeatMinutes! * n));
        if (!at.isAfter(now)) continue;
        await _plugin.zonedSchedule(
          _urgentIdFor(s, n),
          '⚠️ ${med.name} 미복용 알림',
          '아직 복용 체크가 되지 않았어요. 지금 확인해주세요.',
          at,
          _details(NotifTone.urgent),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          // 단발 (matchDateTimeComponents 생략)
          payload: _payload(s, next),
        );
      }
    }
  }

  static const int defaultUrgentMaxRepeats = 6;

  Future<void> _scheduleWeekly(Medication med, Schedule s) async {
    final mask = s.daysOfWeekMask ?? 0;
    // 비트 0=일요일 ... 비트 6=토요일.
    for (var bit = 0; bit < 7; bit++) {
      if ((mask & (1 << bit)) == 0) continue;
      final weekday = bit == 0 ? DateTime.sunday : bit;
      final next = _nextWeeklyOccurrence(s.timeOfDay, weekday);
      await _plugin.zonedSchedule(
        _weeklyIdFor(s, weekday),
        '${med.name} 복용 시간',
        _quantityHint(med),
        next,
        _details(NotifTone.onTime),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: _payload(s, next),
      );
    }
  }

  Future<void> _cancelSchedule(Schedule s) async {
    await _plugin.cancel(_dailyIdFor(s));
    for (var wd = 1; wd <= 7; wd++) {
      await _plugin.cancel(_weeklyIdFor(s, wd));
    }
    await _plugin.cancel(_preReminderIdFor(s));
    await _cancelUrgentSlots(s.id, max: 32);
  }

  /// 오늘 (또는 미래) 등록된 urgent 단발 알림들을 모두 취소.
  /// 사용자가 액션(taken/skipped) 후 호출되어 추가 발화 막음.
  Future<void> cancelUrgentForSchedule(int scheduleId, {int max = 32}) =>
      _cancelUrgentSlots(scheduleId, max: max);

  Future<void> _cancelUrgentSlots(int scheduleId, {required int max}) async {
    for (var n = 1; n <= max; n++) {
      await _plugin.cancel(_urgentIdForSched(scheduleId, n));
    }
  }

  // --- ID 규칙 ----------------------------------------------------------
  //
  // daily/weekly/preReminder는 scheduleId * 10 + [0..9] 범위.
  // urgent는 scheduleId * 1000 + [101..199] 범위 → 자릿수 분리로 충돌 없음.

  int _dailyIdFor(Schedule s) => s.id * 10;
  int _weeklyIdFor(Schedule s, int weekday) => s.id * 10 + weekday;
  int _preReminderIdFor(Schedule s) => s.id * 10 + 9;
  int _urgentIdFor(Schedule s, int n) => s.id * 1000 + 100 + n;
  int _urgentIdForSched(int scheduleId, int n) => scheduleId * 1000 + 100 + n;

  // --- 시각 계산 ---------------------------------------------------------

  tz.TZDateTime _nextOccurrence(String hhmm) {
    final parts = hhmm.split(':');
    final h = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final now = tz.TZDateTime.now(tz.local);
    var t = tz.TZDateTime(tz.local, now.year, now.month, now.day, h, m);
    if (!t.isAfter(now)) t = t.add(const Duration(days: 1));
    return t;
  }

  /// "HH:mm"에서 N분 뺀 새 "HH:mm" (음수면 전날로 wrap).
  String _subtractMinutes(String hhmm, int minutes) {
    final parts = hhmm.split(':');
    var totalMin = int.parse(parts[0]) * 60 + int.parse(parts[1]) - minutes;
    if (totalMin < 0) totalMin += 24 * 60;
    final h = (totalMin ~/ 60).toString().padLeft(2, '0');
    final m = (totalMin % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  tz.TZDateTime _nextWeeklyOccurrence(String hhmm, int weekday) {
    final parts = hhmm.split(':');
    final h = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final now = tz.TZDateTime.now(tz.local);
    var t = tz.TZDateTime(tz.local, now.year, now.month, now.day, h, m);
    while (t.weekday != weekday || !t.isAfter(now)) {
      t = t.add(const Duration(days: 1));
    }
    return t;
  }

  // --- 알림 세부 -----------------------------------------------------------

  NotificationDetails _details(NotifTone tone) {
    final channelId = switch (tone) {
      NotifTone.reminder => NotificationChannels.reminderId,
      NotifTone.onTime => NotificationChannels.onTimeId,
      NotifTone.urgent => NotificationChannels.urgentId,
    };
    final channelName = switch (tone) {
      NotifTone.reminder => NotificationChannels.reminderName,
      NotifTone.onTime => NotificationChannels.onTimeName,
      NotifTone.urgent => NotificationChannels.urgentName,
    };
    final urgent = tone == NotifTone.urgent;
    final android = AndroidNotificationDetails(
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
    const ios = DarwinNotificationDetails(
      categoryIdentifier: NotificationChannels.actionCategory,
      interruptionLevel: InterruptionLevel.timeSensitive,
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    return NotificationDetails(android: android, iOS: ios);
  }

  String _quantityHint(Medication m) {
    final d = m.dosage, u = m.unit;
    if (d != null && u != null) return '$d$u — 복용 후 체크해주세요';
    if (d != null) return '$d — 복용 후 체크해주세요';
    return '복용 후 체크해주세요';
  }

  /// payload: dose:scheduleId:medicationId:isoScheduledAt
  /// 액션 핸들러에서 split(':')로 파싱.
  String _payload(Schedule s, tz.TZDateTime when) {
    final local = DateTime(when.year, when.month, when.day, when.hour, when.minute);
    return 'dose:${s.id}:${s.medicationId}:${local.toIso8601String()}';
  }
}

/// 알림 톤 — 채널/중요도 결정용.
enum NotifTone { reminder, onTime, urgent }

final medicationNotificationManagerProvider =
    Provider<MedicationNotificationManager>((ref) {
  return MedicationNotificationManager(
    ref.watch(notificationServiceProvider),
    ref.watch(appDatabaseProvider),
  );
});
