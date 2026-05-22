import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_providers.dart';
import '../../../core/notifications/medication_notification_manager.dart';
import 'medication_repository.dart';

final trackedMedicationRepositoryProvider = Provider<TrackedMedicationRepository>((ref) {
  return TrackedMedicationRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(medicationNotificationManagerProvider),
  );
});

/// 활성 약 + 스케줄 전체 실시간 스트림.
final trackedMedicationsStreamProvider =
    StreamProvider<List<TrackedMedicationWithSchedules>>((ref) {
  return ref.watch(trackedMedicationRepositoryProvider).watchAll();
});

/// id 별 단일 약 스트림.
final trackedMedicationByIdProvider =
    StreamProvider.family<TrackedMedicationWithSchedules?, int>((ref, id) {
  return ref.watch(trackedMedicationRepositoryProvider).watchById(id);
});


/// 현재 enabled 상태의 schedule들이 사용 중인 "HH:mm" 시각 distinct 목록.
/// 등록 플로우 Step 3에서 quick-pick chip으로 사용 — 기존 알람 시간을 골라
/// 동일 시각에 약을 묶어 알림 받을 수 있도록.
final existingAlarmTimesProvider = StreamProvider<List<String>>((ref) {
  final medsAsync = ref.watch(trackedMedicationsStreamProvider);
  return medsAsync.when(
    loading: () => Stream.value(const <String>[]),
    error: (e, st) => Stream.error(e, st),
    data: (meds) {
      final times = <String>{};
      for (final m in meds) {
        for (final s in m.schedules) {
          if (s.enabled) times.add(s.timeOfDay);
        }
      }
      final sorted = times.toList()..sort();
      return Stream.value(sorted);
    },
  );
});
