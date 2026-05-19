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
    await _plugin.zonedSchedule(
      _dailyIdFor(s),
      '${med.name} 복용 시간',
      _quantityHint(med),
      next,
      _details(urgent: false),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // 매일 같은 시각 반복
      payload: _payload(s, next),
    );
  }

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
        _details(urgent: false),
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
    await _plugin.cancel(_snoozeIdForSched(s.id));
  }

  /// 한 슬롯에 대해 [delay] 뒤 일회성 스누즈 알림 등록.
  ///
  /// daily/weekly 본 알림은 그대로 두고, 스누즈 슬롯(`scheduleId*10+8`)에
  /// 단발로 추가 등록. 기존 스누즈가 있으면 cancel 후 새로 (마지막 호출만 살아남음).
  Future<void> scheduleSnooze({
    required int scheduleId,
    required int medicationId,
    required DateTime originalScheduledAt,
    Duration delay = const Duration(minutes: 10),
  }) async {
    await _plugin.cancel(_snoozeIdForSched(scheduleId));
    final med = await (_db.select(_db.medications)
          ..where((m) => m.id.equals(medicationId)))
        .getSingleOrNull();
    if (med == null || med.archived) return;

    final when = tz.TZDateTime.from(
      DateTime.now().add(delay),
      tz.local,
    );

    await _plugin.zonedSchedule(
      _snoozeIdForSched(scheduleId),
      '${med.name} 복용 시간 (다시 알림)',
      _quantityHint(med),
      when,
      _details(urgent: false),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      // matchDateTimeComponents 생략 → 단 한 번만 발화
      payload: _payloadRaw(
        scheduleId: scheduleId,
        medicationId: medicationId,
        when: originalScheduledAt,
      ),
    );
  }

  // --- ID 규칙 ----------------------------------------------------------

  int _dailyIdFor(Schedule s) => s.id * 10;
  int _weeklyIdFor(Schedule s, int weekday) => s.id * 10 + weekday;
  int _snoozeIdForSched(int scheduleId) => scheduleId * 10 + 8;

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

  NotificationDetails _details({required bool urgent}) {
    final android = AndroidNotificationDetails(
      urgent
          ? NotificationChannels.urgentId
          : NotificationChannels.onTimeId,
      urgent
          ? NotificationChannels.urgentName
          : NotificationChannels.onTimeName,
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
    final local = DateTime(
        when.year, when.month, when.day, when.hour, when.minute);
    return _payloadRaw(
      scheduleId: s.id,
      medicationId: s.medicationId,
      when: local,
    );
  }

  String _payloadRaw({
    required int scheduleId,
    required int medicationId,
    required DateTime when,
  }) {
    return 'dose:$scheduleId:$medicationId:${when.toIso8601String()}';
  }
}

final medicationNotificationManagerProvider =
    Provider<MedicationNotificationManager>((ref) {
  return MedicationNotificationManager(
    ref.watch(notificationServiceProvider),
    ref.watch(appDatabaseProvider),
  );
});
