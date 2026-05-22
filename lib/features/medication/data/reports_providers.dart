import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/tables/intake_logs.dart';
import '../../reports/presentation/widgets/period_tabs.dart';
import 'intake_providers.dart';
import 'intake_repository.dart';
import 'medication_providers.dart';

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

// =============================================================================
// 기간 범위 (PeriodRange)
// =============================================================================

/// 한 보고서 기간의 시간 범위.
class PeriodRange {
  const PeriodRange({
    required this.start,
    required this.end,
    required this.period,
  });

  final DateTime start; // 포함
  final DateTime end; // exclusive
  final ReportPeriod period;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PeriodRange &&
          other.start == start &&
          other.end == end &&
          other.period == period);

  @override
  int get hashCode => Object.hash(start, end, period);
}

/// 지금 시각이 속한 [period]의 시간 범위.
PeriodRange currentPeriodRange(ReportPeriod period) {
  final today = _dateOnly(DateTime.now());
  switch (period) {
    case ReportPeriod.weekly:
      // 월요일 시작 + 7일.
      final mon = today.subtract(Duration(days: today.weekday - 1));
      return PeriodRange(
        start: mon,
        end: mon.add(const Duration(days: 7)),
        period: period,
      );
    case ReportPeriod.monthly:
      final first = DateTime(today.year, today.month, 1);
      final nextMonth = DateTime(today.year, today.month + 1, 1);
      return PeriodRange(start: first, end: nextMonth, period: period);
    case ReportPeriod.yearly:
      final first = DateTime(today.year, 1, 1);
      final next = DateTime(today.year + 1, 1, 1);
      return PeriodRange(start: first, end: next, period: period);
  }
}

/// [period] 직전 기간의 시간 범위 (delta 비교용).
PeriodRange priorPeriodRange(ReportPeriod period) {
  final cur = currentPeriodRange(period);
  switch (period) {
    case ReportPeriod.weekly:
      return PeriodRange(
        start: cur.start.subtract(const Duration(days: 7)),
        end: cur.start,
        period: period,
      );
    case ReportPeriod.monthly:
      final s = DateTime(cur.start.year, cur.start.month - 1, 1);
      return PeriodRange(start: s, end: cur.start, period: period);
    case ReportPeriod.yearly:
      final s = DateTime(cur.start.year - 1, 1, 1);
      return PeriodRange(start: s, end: cur.start, period: period);
  }
}

// =============================================================================
// Doses by range
// =============================================================================

/// [range] 안 일자별 dose 묶음을 한 번에 계산.
///
/// monthly/yearly에선 31~365일 분량을 한 번에 처리. 한 약·스케줄 세트 기준
/// computeDosesForDay()를 일자별로 호출 — log은 한 번만 가져옴.
final dosesByRangeProvider = FutureProvider.family
    .autoDispose<Map<DateTime, List<DoseInstance>>, PeriodRange>(
        (ref, range) async {
  final repo = ref.watch(intakeRepositoryProvider);
  final medsAsync = ref.watch(trackedMedicationsStreamProvider);

  return medsAsync.when(
    loading: () async => <DateTime, List<DoseInstance>>{},
    error: (e, st) async => throw e,
    data: (medsWithSchedules) async {
      final logs = await repo.getRange(range.start, range.end);
      final meds = medsWithSchedules.map((m) => m.medication).toList();
      final catalogByMedId = {
        for (final m in medsWithSchedules) m.medication.id: m.catalog,
      };
      final scheds = [for (final m in medsWithSchedules) ...m.schedules];

      final out = <DateTime, List<DoseInstance>>{};
      for (var d = range.start;
          d.isBefore(range.end);
          d = d.add(const Duration(days: 1))) {
        out[d] = computeDosesForDay(
          date: d,
          meds: meds,
          catalogByMedId: catalogByMedId,
          schedules: scheds,
          logs: logs,
        );
      }
      return out;
    },
  );
});

// =============================================================================
// Period summary (done / pending / missed / total)
// =============================================================================

class PeriodSummary {
  const PeriodSummary({
    required this.range,
    required this.done,
    required this.pending,
    required this.missed,
    required this.total,
  });

  final PeriodRange range;
  final int done;
  final int pending;
  final int missed;
  final int total;

  double get progress => total == 0 ? 0 : done / total;
}

PeriodSummary _summarize(
  PeriodRange range,
  Map<DateTime, List<DoseInstance>> byDay,
) {
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
  return PeriodSummary(
    range: range,
    done: done,
    pending: pending,
    missed: missed,
    total: total,
  );
}

/// [period] 현재 범위의 요약.
final periodSummaryProvider =
    Provider.family<AsyncValue<PeriodSummary>, ReportPeriod>((ref, period) {
  final range = currentPeriodRange(period);
  return ref
      .watch(dosesByRangeProvider(range))
      .whenData((byDay) => _summarize(range, byDay));
});

/// [period] 직전 범위의 요약 (delta 계산용).
final _priorPeriodSummaryProvider =
    Provider.family<AsyncValue<PeriodSummary>, ReportPeriod>((ref, period) {
  final range = priorPeriodRange(period);
  return ref
      .watch(dosesByRangeProvider(range))
      .whenData((byDay) => _summarize(range, byDay));
});

/// 현재 [period] 완료율 − 직전 [period] 완료율 (정수 %p). 비교 데이터 없으면 null.
final periodDeltaPercentProvider =
    Provider.family<AsyncValue<int?>, ReportPeriod>((ref, period) {
  final cur = ref.watch(periodSummaryProvider(period));
  final prev = ref.watch(_priorPeriodSummaryProvider(period));
  return cur.whenData((c) {
    final p = prev.value;
    if (p == null || p.total == 0) return null;
    if (c.total == 0) return null;
    return (c.progress * 100).round() - (p.progress * 100).round();
  });
});

/// [period] 총 완료 횟수.
final periodTotalCompletedProvider =
    Provider.family<AsyncValue<int>, ReportPeriod>((ref, period) {
  return ref.watch(periodSummaryProvider(period)).whenData((s) => s.done);
});

// =============================================================================
// Period buckets (chart bars)
// =============================================================================

/// 차트 막대 1개.
class PeriodBucket {
  const PeriodBucket({
    required this.label,
    required this.date,
    required this.percent,
    required this.isCurrent,
  });

  final String label; // "월"/"오늘"/"1주"/"1월"
  final DateTime date; // 캘린더 점프용 대표 일자
  final int percent; // 0~100
  final bool isCurrent; // 오늘 / 이번 주 / 이번 달
}

int _percentOf(List<DoseInstance> doses) {
  if (doses.isEmpty) return 0;
  final done = doses.where((d) => d.status == IntakeStatus.taken).length;
  return ((done / doses.length) * 100).round();
}

List<PeriodBucket> _computeBuckets(
  PeriodRange range,
  Map<DateTime, List<DoseInstance>> byDay,
) {
  final today = _dateOnly(DateTime.now());
  switch (range.period) {
    case ReportPeriod.weekly:
      final keys = byDay.keys.toList()..sort();
      return [
        for (final d in keys)
          PeriodBucket(
            label: shortKoreanDay(d),
            date: d,
            percent: _percentOf(byDay[d] ?? const []),
            isCurrent: d == today,
          ),
      ];

    case ReportPeriod.monthly:
      // week-of-month: ((day-1)/7)+1 → 1..5
      final byWeek = <int, List<DoseInstance>>{};
      final firstDateOfWeek = <int, DateTime>{};
      for (final entry in byDay.entries) {
        final w = ((entry.key.day - 1) ~/ 7) + 1;
        (byWeek[w] ??= []).addAll(entry.value);
        firstDateOfWeek.putIfAbsent(w, () => entry.key);
      }
      final weeks = byWeek.keys.toList()..sort();
      final curWeek = ((today.day - 1) ~/ 7) + 1;
      final sameMonth = today.year == range.start.year &&
          today.month == range.start.month;
      return [
        for (final w in weeks)
          PeriodBucket(
            label: '$w주',
            date: firstDateOfWeek[w] ?? range.start,
            percent: _percentOf(byWeek[w] ?? const []),
            isCurrent: sameMonth && w == curWeek,
          ),
      ];

    case ReportPeriod.yearly:
      final byMonth = <int, List<DoseInstance>>{};
      for (final entry in byDay.entries) {
        (byMonth[entry.key.month] ??= []).addAll(entry.value);
      }
      final sameYear = today.year == range.start.year;
      return [
        for (var m = 1; m <= 12; m++)
          PeriodBucket(
            label: '$m월',
            date: DateTime(range.start.year, m, 1),
            percent: _percentOf(byMonth[m] ?? const []),
            isCurrent: sameYear && today.month == m,
          ),
      ];
  }
}

/// [period] 차트용 막대 리스트 (granularity는 period에 따라 변동).
final periodBucketsProvider =
    Provider.family<AsyncValue<List<PeriodBucket>>, ReportPeriod>(
        (ref, period) {
  final range = currentPeriodRange(period);
  return ref
      .watch(dosesByRangeProvider(range))
      .whenData((byDay) => _computeBuckets(range, byDay));
});

// =============================================================================
// Best time of day
// =============================================================================

class BestTimeOfDay {
  const BestTimeOfDay({required this.timeOfDay, required this.completionRate});
  final String timeOfDay; // "HH:mm"
  final double completionRate;
}

final periodBestTimeOfDayProvider =
    Provider.family<AsyncValue<BestTimeOfDay?>, ReportPeriod>((ref, period) {
  final range = currentPeriodRange(period);
  return ref.watch(dosesByRangeProvider(range)).whenData((byDay) {
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

// =============================================================================
// Streak (period 무관, 오늘부터 거꾸로)
// =============================================================================

/// 연속 복용 일수 — 오늘부터 거꾸로, 그 날 dose가 모두 taken이면 streak +1.
final streakProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(intakeRepositoryProvider);
  final medsAsync = ref.watch(trackedMedicationsStreamProvider);

  return medsAsync.when(
    loading: () async => 0,
    error: (_, _) async => 0,
    data: (medsWithSchedules) async {
      if (medsWithSchedules.isEmpty) return 0;
      final meds = medsWithSchedules.map((m) => m.medication).toList();
      final catalogByMedId = {
        for (final m in medsWithSchedules) m.medication.id: m.catalog,
      };
      final scheds = [for (final m in medsWithSchedules) ...m.schedules];

      final today = _dateOnly(DateTime.now());
      var streak = 0;
      for (var i = 0; i < 90; i++) {
        final day = today.subtract(Duration(days: i));
        final dayEnd = day.add(const Duration(days: 1));
        final logs = await repo.getRange(day, dayEnd);
        final doses = computeDosesForDay(
          date: day,
          meds: meds,
          catalogByMedId: catalogByMedId,
          schedules: scheds,
          logs: logs,
        );
        if (doses.isEmpty) break;
        final allTaken = doses.every((d) => d.status == IntakeStatus.taken);
        if (!allTaken) break;
        streak++;
      }
      return streak;
    },
  );
});

// =============================================================================
// 표시 헬퍼
// =============================================================================

/// 주중 일자 표시용 한국어 약어.
String shortKoreanDay(DateTime d) {
  final today = _dateOnly(DateTime.now());
  if (d == today) return '오늘';
  const names = ['월', '화', '수', '목', '금', '토', '일'];
  return names[d.weekday - 1];
}

/// "5월 13일 - 5월 19일" / "2026년 5월" / "2026년" 형태의 라벨.
String periodRangeLabel(PeriodRange r) {
  switch (r.period) {
    case ReportPeriod.weekly:
      final last = r.end.subtract(const Duration(days: 1));
      return '${r.start.month}월 ${r.start.day}일 - ${last.month}월 ${last.day}일';
    case ReportPeriod.monthly:
      return '${r.start.year}년 ${r.start.month}월';
    case ReportPeriod.yearly:
      return '${r.start.year}년';
  }
}

/// 카드 제목 라벨.
String periodTitleLabel(ReportPeriod period) => switch (period) {
      ReportPeriod.weekly => '이번 주 리포트',
      ReportPeriod.monthly => '이번 달 리포트',
      ReportPeriod.yearly => '올해 리포트',
    };

/// 차트 제목 라벨.
String periodChartTitle(ReportPeriod period) => switch (period) {
      ReportPeriod.weekly => '최근 7일 복용 추이',
      ReportPeriod.monthly => '이번 달 주별 추이',
      ReportPeriod.yearly => '올해 월별 추이',
    };
