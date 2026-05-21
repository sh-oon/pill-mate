import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/notifications/notification_service.dart';

/// 사용자 데이터 전체 초기화 — 약/스케줄/복용 기록/인터벌 발생/예약된 알림.
/// 온보딩 플래그/앱 설정은 건드리지 않음 (별도 옵션으로 추후 확장).
class DataResetService {
  DataResetService(this._db, this._notif);

  final AppDatabase _db;
  final NotificationService _notif;

  Future<void> resetAll() async {
    await _notif.plugin.cancelAll();
    await _db.transaction(() async {
      await _db.delete(_db.intakeLogs).go();
      await _db.delete(_db.intervalOccurrences).go();
      await _db.delete(_db.schedules).go();
      await _db.delete(_db.trackedMedications).go();
    });
  }
}

final dataResetServiceProvider = Provider<DataResetService>((ref) {
  return DataResetService(
    ref.watch(appDatabaseProvider),
    ref.watch(notificationServiceProvider),
  );
});
