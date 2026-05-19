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
        await _scheduleInterval(med, schedule);
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

  /// Interval 약: 향후 [target]개 occurrence를 DB 큐에 채우고 각각 단발 알림 등록.
  /// 이미 큐에 있는 occurrence는 재사용. 사용자 액션 후 또는 부팅 시 재호출되어
  /// 큐 길이 유지.
  Future<void> _scheduleInterval(
    Medication med,
    Schedule s, {
    int target = 7,
  }) async {
    final n = s.intervalDays ?? 1;
    if (n <= 0) return;

    final today = _dateOnly(DateTime.now());

    // 1) 과거 occurrence 정리.
    await (_db.delete(_db.intervalOccurrences)
          ..where((o) =>
              o.scheduleId.equals(s.id) &
              o.scheduledAt.isSmallerThanValue(today)))
        .go();

    // 2) 현재 큐 조회.
    final upcoming = await (_db.select(_db.intervalOccurrences)
          ..where((o) => o.scheduleId.equals(s.id))
          ..orderBy([(o) => OrderingTerm.asc(o.scheduledAt)]))
        .get();

    // 3) 부족분 보강 — startDate 기준 N일 step.
    DateTime nextDate;
    if (upcoming.isEmpty) {
      // 첫 occurrence = today >= startDate인 가장 빠른 N일 단계.
      nextDate = _dateOnly(s.startDate);
      while (nextDate.isBefore(today)) {
        nextDate = nextDate.add(Duration(days: n));
      }
    } else {
      nextDate = _dateOnly(upcoming.last.scheduledAt).add(Duration(days: n));
    }

    final toAdd = target - upcoming.length;
    for (var i = 0; i < toAdd; i++) {
      final at = _combineDateAndTime(nextDate, s.timeOfDay);
      await _db.into(_db.intervalOccurrences).insert(
            IntervalOccurrencesCompanion.insert(
              scheduleId: s.id,
              scheduledAt: at,
            ),
          );
      nextDate = nextDate.add(Duration(days: n));
    }

    // 4) DB 큐 전체를 OS 알림으로 (재)등록. 단발이므로 매번 register OK.
    final all = await (_db.select(_db.intervalOccurrences)
          ..where((o) => o.scheduleId.equals(s.id))
          ..orderBy([(o) => OrderingTerm.asc(o.scheduledAt)]))
        .get();
    final now = tz.TZDateTime.now(tz.local);
    for (final occ in all) {
      final when = tz.TZDateTime.from(occ.scheduledAt, tz.local);
      if (!when.isAfter(now)) continue;
      await _plugin.zonedSchedule(
        _intervalIdForOccurrence(occ.id),
        '${med.name} 복용 시간',
        _quantityHint(med),
        when,
        _details(urgent: false),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        // 단발 (matchDateTimeComponents 생략)
        payload: _payloadAt(s, occ.scheduledAt),
      );
    }
  }

  Future<void> _cancelSchedule(Schedule s) async {
    await _plugin.cancel(_dailyIdFor(s));
    for (var wd = 1; wd <= 7; wd++) {
      await _plugin.cancel(_weeklyIdFor(s, wd));
    }
    // Interval occurrences cancel + DB 큐 비우기.
    final occs = await (_db.select(_db.intervalOccurrences)
          ..where((o) => o.scheduleId.equals(s.id)))
        .get();
    for (final o in occs) {
      await _plugin.cancel(_intervalIdForOccurrence(o.id));
    }
    await (_db.delete(_db.intervalOccurrences)
          ..where((o) => o.scheduleId.equals(s.id)))
        .go();
  }

  // --- ID 규칙 ----------------------------------------------------------
  // daily: scheduleId * 10
  // weekly: scheduleId * 10 + weekday(1..7)
  // interval: 100_000_000 + occurrenceId
  //   - occurrence id는 별도 시퀀스라 scheduleId와 자릿수 분리만 보장하면 됨.

  int _dailyIdFor(Schedule s) => s.id * 10;
  int _weeklyIdFor(Schedule s, int weekday) => s.id * 10 + weekday;
  int _intervalIdForOccurrence(int occurrenceId) =>
      100000000 + occurrenceId;

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
    return _payloadAt(s, local);
  }

  String _payloadAt(Schedule s, DateTime when) {
    return 'dose:${s.id}:${s.medicationId}:${when.toIso8601String()}';
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _combineDateAndTime(DateTime date, String hhmm) {
    final p = hhmm.split(':');
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(p[0]),
      int.parse(p[1]),
    );
  }
}

final medicationNotificationManagerProvider =
    Provider<MedicationNotificationManager>((ref) {
  return MedicationNotificationManager(
    ref.watch(notificationServiceProvider),
    ref.watch(appDatabaseProvider),
  );
});
