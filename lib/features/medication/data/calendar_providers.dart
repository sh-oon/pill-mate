import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/tables/intake_logs.dart';
import 'intake_providers.dart';
import 'intake_repository.dart';
import 'medication_providers.dart';

/// 특정 일자 dose 목록.
final dayDosesProvider =
    FutureProvider.family<List<DoseInstance>, DateTime>((ref, date) async {
  final repo = ref.watch(intakeRepositoryProvider);
  final medsAsync = ref.watch(medicationsStreamProvider);

  return medsAsync.when(
    loading: () async => <DoseInstance>[],
    error: (e, st) async => throw e,
    data: (medsWithSchedules) async {
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));
      final logs = await repo.getRange(start, end);
      final meds = medsWithSchedules.map((m) => m.medication).toList();
      final scheds = [for (final m in medsWithSchedules) ...m.schedules];
      return computeDosesForDay(
        date: date,
        meds: meds,
        schedules: scheds,
        logs: logs,
      );
    },
  );
});

/// 캘린더 한 일자 마크 종류.
enum DayMarkKind { none, completed, scheduled, missed }

/// 캘린더 일자 기록 필터.
enum DayFilter { all, completed, scheduled, missed }

extension DayFilterX on DayFilter {
  IntakeStatus toStatus() => switch (this) {
        DayFilter.completed => IntakeStatus.taken,
        DayFilter.scheduled => IntakeStatus.pending,
        DayFilter.missed => IntakeStatus.missed,
        DayFilter.all => throw StateError('all has no single status'),
      };
}

/// 캘린더 화면에서 현재 선택된 일자 필터.
/// 홈 → 캘린더 진입 시 필터를 미리 지정할 수 있도록 전역 상태로 노출.
class CalendarFilterNotifier extends Notifier<DayFilter> {
  @override
  DayFilter build() => DayFilter.all;
  void set(DayFilter value) => state = value;
}

final calendarFilterProvider =
    NotifierProvider<CalendarFilterNotifier, DayFilter>(
  CalendarFilterNotifier.new,
);

/// 홈에서 캘린더로 이동할 때 보고 싶은 날짜를 미리 지정하기 위한 신호.
/// null이면 캘린더 화면이 자체 보유한 선택 상태를 유지.
class CalendarJumpDateNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;
  void set(DateTime? value) => state = value;
}

final calendarJumpDateProvider =
    NotifierProvider<CalendarJumpDateNotifier, DateTime?>(
  CalendarJumpDateNotifier.new,
);

/// 한 달 모든 일자의 마크 상태를 한 번에 계산.
final monthMarksProvider = FutureProvider.family
    .autoDispose<Map<int, DayMarkKind>, ({int year, int month})>((ref, key) async {
  final repo = ref.watch(intakeRepositoryProvider);
  final medsAsync = ref.watch(medicationsStreamProvider);

  return medsAsync.when(
    loading: () async => <int, DayMarkKind>{},
    error: (e, st) async => throw e,
    data: (medsWithSchedules) async {
      final first = DateTime(key.year, key.month, 1);
      final next = DateTime(key.year, key.month + 1, 1);
      final daysInMonth = next.difference(first).inDays;

      final logs = await repo.getRange(first, next);
      final meds = medsWithSchedules.map((m) => m.medication).toList();
      final scheds = [for (final m in medsWithSchedules) ...m.schedules];

      final out = <int, DayMarkKind>{};
      for (var d = 1; d <= daysInMonth; d++) {
        final date = DateTime(key.year, key.month, d);
        final doses = computeDosesForDay(
          date: date,
          meds: meds,
          schedules: scheds,
          logs: logs,
        );
        if (doses.isEmpty) {
          out[d] = DayMarkKind.none;
          continue;
        }
        final hasMissed = doses.any((x) => x.status == IntakeStatus.missed);
        if (hasMissed) {
          out[d] = DayMarkKind.missed;
          continue;
        }
        final hasPending = doses.any((x) => x.status == IntakeStatus.pending);
        if (hasPending) {
          out[d] = DayMarkKind.scheduled;
          continue;
        }
        // 모두 taken/skipped
        out[d] = DayMarkKind.completed;
      }
      return out;
    },
  );
});
