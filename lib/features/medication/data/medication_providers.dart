import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_providers.dart';
import '../../../core/notifications/medication_notification_manager.dart';
import 'medication_repository.dart';

final medicationRepositoryProvider = Provider<MedicationRepository>((ref) {
  return MedicationRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(medicationNotificationManagerProvider),
  );
});

/// 활성 약 + 스케줄 전체 실시간 스트림.
final medicationsStreamProvider =
    StreamProvider<List<MedicationWithSchedules>>((ref) {
  return ref.watch(medicationRepositoryProvider).watchAll();
});

/// id 별 단일 약 스트림.
final medicationByIdProvider =
    StreamProvider.family<MedicationWithSchedules?, int>((ref, id) {
  return ref.watch(medicationRepositoryProvider).watchById(id);
});
