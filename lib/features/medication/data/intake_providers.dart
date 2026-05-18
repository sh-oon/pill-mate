import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/database/tables/intake_logs.dart';
import 'intake_repository.dart';
import 'medication_providers.dart';

final intakeRepositoryProvider = Provider<IntakeRepository>((ref) {
  return IntakeRepository(ref.watch(appDatabaseProvider));
});

/// 오늘 IntakeLog 스트림.
final todayLogsProvider = StreamProvider<List<IntakeLog>>((ref) {
  return ref.watch(intakeRepositoryProvider).watchDay(DateTime.now());
});

/// 오늘의 dose 계산 — meds(스케줄 포함) + logs를 결합.
final todayDosesProvider = Provider<AsyncValue<List<DoseInstance>>>((ref) {
  final medsAsync = ref.watch(medicationsStreamProvider);
  final logsAsync = ref.watch(todayLogsProvider);

  return medsAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
    data: (medsWithSchedules) {
      return logsAsync.when(
        loading: () => const AsyncValue.loading(),
        error: (e, st) => AsyncValue.error(e, st),
        data: (logs) {
          final meds = medsWithSchedules.map((m) => m.medication).toList();
          final scheds = [
            for (final m in medsWithSchedules) ...m.schedules,
          ];
          return AsyncValue.data(computeDosesForDay(
            date: DateTime.now(),
            meds: meds,
            schedules: scheds,
            logs: logs,
          ));
        },
      );
    },
  );
});

/// 오늘 카운트 (완료/예정/놓침/전체).
class TodayCounts {
  const TodayCounts({
    required this.done,
    required this.pending,
    required this.missed,
    required this.total,
  });

  final int done;
  final int pending;
  final int missed;
  final int total;

  int get scheduled => pending;
  double get progress => total == 0 ? 0 : done / total;
}

final todayCountsProvider = Provider<AsyncValue<TodayCounts>>((ref) {
  final dosesAsync = ref.watch(todayDosesProvider);
  return dosesAsync.whenData((doses) {
    var done = 0, pending = 0, missed = 0;
    for (final d in doses) {
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
          // skipped는 total에는 포함, 완료/예정/놓침 어디에도 안 들어감
          break;
      }
    }
    return TodayCounts(
      done: done,
      pending: pending,
      missed: missed,
      total: doses.length,
    );
  });
});

/// 다음 복용 (현재 시각 이후 가장 가까운 pending).
final todayNextDoseProvider = Provider<AsyncValue<DoseInstance?>>((ref) {
  final dosesAsync = ref.watch(todayDosesProvider);
  return dosesAsync.whenData((doses) {
    final now = DateTime.now();
    DoseInstance? best;
    for (final d in doses) {
      if (d.status != IntakeStatus.pending) continue;
      if (d.scheduledAt.isBefore(now)) continue;
      if (best == null || d.scheduledAt.isBefore(best.scheduledAt)) {
        best = d;
      }
    }
    return best;
  });
});

/// 가장 오래된 missed (홈 "놓친 복용" 배너용). 어제~오늘 missed 중.
final recentMissedProvider = StreamProvider<DoseInstance?>((ref) {
  // 어제 + 오늘 두 일자 dose를 합쳐 missed 중 가장 오래된 것 반환.
  // 단순화: 오늘 dose 중 missed 우선, 없으면 null.
  final dosesAsync = ref.watch(todayDosesProvider);
  return dosesAsync.when(
    loading: () => const Stream.empty(),
    error: (e, st) => Stream.error(e, st),
    data: (doses) {
      final missed = doses.where((d) => d.status == IntakeStatus.missed).toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      return Stream.value(missed.isEmpty ? null : missed.first);
    },
  );
});
