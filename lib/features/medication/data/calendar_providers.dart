import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/tables/intake_logs.dart';
import 'intake_providers.dart';
import 'intake_repository.dart';
import 'medication_providers.dart';

/// 특정 일자 dose 스트림.
///
/// meds 스트림 + 해당 일자 intake_logs 스트림을 결합해서 markTaken/markSkipped
/// 후 자동으로 재계산. (기존엔 FutureProvider + getRange 였어서 홈에서 상태
/// 변경해도 캘린더는 stale 데이터 표시 — 버그 수정.)
final dayDosesProvider =
    StreamProvider.family<List<DoseInstance>, DateTime>((ref, date) {
  final repo = ref.watch(intakeRepositoryProvider);
  final start = DateTime(date.year, date.month, date.day);
  final end = start.add(const Duration(days: 1));

  final medsAsync = ref.watch(trackedMedicationsStreamProvider);
  return medsAsync.when(
    loading: () => const Stream.empty(),
    error: (e, st) => Stream.error(e, st),
    data: (medsWithSchedules) {
      final meds = medsWithSchedules.map((m) => m.medication).toList();
      final scheds = [for (final m in medsWithSchedules) ...m.schedules];
      return repo.watchRange(start, end).map((logs) {
        return computeDosesForDay(
          date: date,
          meds: meds,
          schedules: scheds,
          logs: logs,
        );
      });
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

/// 한 달 모든 일자의 마크 상태 스트림.
///
/// dayDosesProvider와 동일 이유로 StreamProvider — intake_logs 변경이 즉시
/// 캘린더 월 뷰에 반영되어야 함.
final monthMarksProvider = StreamProvider.family
    .autoDispose<Map<int, DayMarkKind>, ({int year, int month})>((ref, key) {
  final repo = ref.watch(intakeRepositoryProvider);
  final first = DateTime(key.year, key.month, 1);
  final next = DateTime(key.year, key.month + 1, 1);
  final daysInMonth = next.difference(first).inDays;

  final medsAsync = ref.watch(trackedMedicationsStreamProvider);
  return medsAsync.when(
    loading: () => const Stream.empty(),
    error: (e, st) => Stream.error(e, st),
    data: (medsWithSchedules) {
      final meds = medsWithSchedules.map((m) => m.medication).toList();
      final scheds = [for (final m in medsWithSchedules) ...m.schedules];

      return repo.watchRange(first, next).map((logs) {
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
      });
    },
  );
});
