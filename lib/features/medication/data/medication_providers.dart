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
