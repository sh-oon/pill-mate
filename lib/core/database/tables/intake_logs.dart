import 'package:drift/drift.dart';

import 'medications.dart';
import 'schedules.dart';

/// 복용 상태
/// - pending: 예정 (아직 시각 도래 전)
/// - taken: 복용 완료
/// - skipped: 사용자가 건너뜀
/// - missed: 자동 미복용 처리 (예정 시각 + grace 경과)
enum IntakeStatus { pending, taken, skipped, missed }

class IntakeLogs extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get medicationId =>
      integer().references(Medications, #id, onDelete: KeyAction.cascade)();
  IntColumn get scheduleId =>
      integer().references(Schedules, #id, onDelete: KeyAction.cascade)();

  /// 예정된 시각 (로컬 wallclock 기준 DateTime)
  DateTimeColumn get scheduledAt => dateTime()();

  /// 실제 복용 완료/건너뜀 처리 시각
  DateTimeColumn get actedAt => dateTime().nullable()();

  IntColumn get status =>
      intEnum<IntakeStatus>().withDefault(Constant(IntakeStatus.pending.index))();

  /// 긴급 알람이 몇 번 울렸는지
  IntColumn get urgentFiredCount =>
      integer().withDefault(const Constant(0))();

  TextColumn get memo => text().nullable()();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}
