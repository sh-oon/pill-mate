import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/tables/intake_logs.dart';
import 'intake_providers.dart';
import 'intake_repository.dart';
import 'medication_providers.dart';

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// 이번 주 (월요일 시작) 기준 [start, end).
({DateTime start, DateTime end}) _currentWeek() {
  final today = _dateOnly(DateTime.now());
  final mon = today.subtract(Duration(days: today.weekday - 1));
  return (start: mon, end: mon.add(const Duration(days: 7)));
}

/// 임의의 주(월요일 시작) 일자별 dose 묶음.
final dosesByWeekStartProvider = FutureProvider.family
    .autoDispose<Map<DateTime, List<DoseInstance>>, DateTime>(
        (ref, weekStart) async {
  final repo = ref.watch(intakeRepositoryProvider);
  final medsAsync = ref.watch(medicationsStreamProvider);
  final start = _dateOnly(weekStart);
  final end = start.add(const Duration(days: 7));

  return medsAsync.when(
    loading: () async => <DateTime, List<DoseInstance>>{},
    error: (e, st) async => throw e,
    data: (medsWithSchedules) async {
      final logs = await repo.getRange(start, end);
      final meds = medsWithSchedules.map((m) => m.medication).toList();
      final scheds = [for (final m in medsWithSchedules) ...m.schedules];

      final out = <DateTime, List<DoseInstance>>{};
      for (var d = start; d.isBefore(end); d = d.add(const Duration(days: 1))) {
        out[d] = computeDosesForDay(
          date: d,
          meds: meds,
          schedules: scheds,
          logs: logs,
        );
      }
      return out;
    },
  );
});

/// 이번 주 dose 묶음.
final _weeklyDosesProvider =
    FutureProvider<Map<DateTime, List<DoseInstance>>>((ref) {
  return ref.watch(dosesByWeekStartProvider(_currentWeek().start).future);
});

/// 지난 주 dose 묶음.
final _priorWeeklyDosesProvider =
    FutureProvider<Map<DateTime, List<DoseInstance>>>((ref) {
  final prior = _currentWeek().start.subtract(const Duration(days: 7));
  return ref.watch(dosesByWeekStartProvider(prior).future);
});

class WeeklySummary {
  const WeeklySummary({
    required this.weekStart,
    required this.weekEnd,
    required this.done,
    required this.pending,
    required this.missed,
    required this.total,
  });

  final DateTime weekStart;
  final DateTime weekEnd; // exclusive
  final int done;
  final int pending;
  final int missed;
  final int total;

  double get progress => total == 0 ? 0 : done / total;
}

final weeklySummaryProvider =
    Provider<AsyncValue<WeeklySummary>>((ref) {
  final w = _currentWeek();
  return ref.watch(_weeklyDosesProvider).whenData((byDay) {
    var done = 0, pending = 0, missed = 0, total = 0;
    for (final list in byDay.values) {
      for (final d in list) {
        total++;
        switch (d.status) {
          case IntakeStatus.taken:
            done++;
            break;
          case IntakeStatus.pending:
            pending++;
            break;
          case IntakeStatus.missed:
            missed++;
            break;
          case IntakeStatus.skipped:
            break;
        }
      }
    }
    return WeeklySummary(
      weekStart: w.start,
      weekEnd: w.end,
      done: done,
      pending: pending,
      missed: missed,
      total: total,
    );
  });
});

/// 7일 막대 — 일자별 완료율 % (0~100).
class DailyPercent {
  const DailyPercent({
    required this.date,
    required this.percent,
    required this.isToday,
  });

  final DateTime date;
  final int percent;
  final bool isToday;
}

final dailyPercentsProvider =
    Provider<AsyncValue<List<DailyPercent>>>((ref) {
  final today = _dateOnly(DateTime.now());
  return ref.watch(_weeklyDosesProvider).whenData((byDay) {
    final sortedKeys = byDay.keys.toList()..sort();
    return [
      for (final d in sortedKeys)
        DailyPercent(
          date: d,
          percent: _percentOf(byDay[d] ?? const []),
          isToday: d == today,
        ),
    ];
  });
});

int _percentOf(List<DoseInstance> doses) {
  if (doses.isEmpty) return 0;
  final done = doses.where((d) => d.status == IntakeStatus.taken).length;
  return ((done / doses.length) * 100).round();
}

/// 연속 복용 일수 (오늘부터 거꾸로, 그 날 dose가 모두 taken이면 streak +1).
final streakProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(intakeRepositoryProvider);
  final medsAsync = ref.watch(medicationsStreamProvider);

  return medsAsync.when(
    loading: () async => 0,
    error: (_, _) async => 0,
    data: (medsWithSchedules) async {
      if (medsWithSchedules.isEmpty) return 0;
      final meds = medsWithSchedules.map((m) => m.medication).toList();
      final scheds = [for (final m in medsWithSchedules) ...m.schedules];

      final today = _dateOnly(DateTime.now());
      var streak = 0;
      // 최대 90일 확인 (안전 상한).
      for (var i = 0; i < 90; i++) {
        final day = today.subtract(Duration(days: i));
        final dayStart = day;
        final dayEnd = day.add(const Duration(days: 1));
        final logs = await repo.getRange(dayStart, dayEnd);
        final doses = computeDosesForDay(
          date: day,
          meds: meds,
          schedules: scheds,
          logs: logs,
        );
        if (doses.isEmpty) {
          // 빈 날은 streak 깨지 않고 종료 (기준 모호 — 일단 중단).
          break;
        }
        final allTaken =
            doses.every((d) => d.status == IntakeStatus.taken);
        if (!allTaken) break;
        streak++;
      }
      return streak;
    },
  );
});

/// 가장 잘 챙긴 시간대 (각 시각 슬롯 완료율 1위).
class BestTimeOfDay {
  const BestTimeOfDay({required this.timeOfDay, required this.completionRate});
  final String timeOfDay; // "HH:mm"
  final double completionRate;
}

final bestTimeOfDayProvider =
    Provider<AsyncValue<BestTimeOfDay?>>((ref) {
  return ref.watch(_weeklyDosesProvider).whenData((byDay) {
    final byTime = <String, ({int taken, int total})>{};
    for (final list in byDay.values) {
      for (final d in list) {
        final cur = byTime[d.timeOfDay] ?? (taken: 0, total: 0);
        byTime[d.timeOfDay] = (
          taken: cur.taken + (d.status == IntakeStatus.taken ? 1 : 0),
          total: cur.total + 1,
        );
      }
    }
    BestTimeOfDay? best;
    byTime.forEach((time, c) {
      if (c.total < 3) return; // 너무 적은 표본 제외
      final rate = c.taken / c.total;
      if (best == null || rate > best!.completionRate) {
        best = BestTimeOfDay(timeOfDay: time, completionRate: rate);
      }
    });
    return best;
  });
});

/// 이번 주 총 완료 횟수.
final weeklyTotalCompletedProvider = Provider<AsyncValue<int>>((ref) {
  return ref.watch(weeklySummaryProvider).whenData((s) => s.done);
});

/// 지난 주 요약 (delta 계산용).
final _priorWeeklySummaryProvider =
    Provider<AsyncValue<WeeklySummary>>((ref) {
  final prior = _currentWeek().start.subtract(const Duration(days: 7));
  return ref.watch(_priorWeeklyDosesProvider).whenData((byDay) {
    var done = 0, pending = 0, missed = 0, total = 0;
    for (final list in byDay.values) {
      for (final d in list) {
        total++;
        switch (d.status) {
          case IntakeStatus.taken:
            done++;
            break;
          case IntakeStatus.pending:
            pending++;
            break;
          case IntakeStatus.missed:
            missed++;
            break;
          case IntakeStatus.skipped:
            break;
        }
      }
    }
    return WeeklySummary(
      weekStart: prior,
      weekEnd: prior.add(const Duration(days: 7)),
      done: done,
      pending: pending,
      missed: missed,
      total: total,
    );
  });
});

/// 이번 주 완료율 − 지난 주 완료율 (정수 %p).
/// 지난 주 데이터가 없으면 null.
final weekDeltaPercentProvider = Provider<AsyncValue<int?>>((ref) {
  final cur = ref.watch(weeklySummaryProvider);
  final prev = ref.watch(_priorWeeklySummaryProvider);
  return cur.whenData((c) {
    final p = prev.value;
    if (p == null || p.total == 0) return null;
    if (c.total == 0) return null;
    final curPct = (c.progress * 100).round();
    final prevPct = (p.progress * 100).round();
    return curPct - prevPct;
  });
});

/// 주중 일자 표시용 한국어 약어.
String shortKoreanDay(DateTime d) {
  final today = _dateOnly(DateTime.now());
  if (d == today) return '오늘';
  const names = ['월', '화', '수', '목', '금', '토', '일'];
  return names[d.weekday - 1];
}

/// 5월 10일 - 5월 16일 형태.
String weekRangeLabel(DateTime start, DateTime endExclusive) {
  final last = endExclusive.subtract(const Duration(days: 1));
  return '${start.month}월 ${start.day}일 - ${last.month}월 ${last.day}일';
}

