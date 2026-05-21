import 'package:drift/drift.dart';

import 'schedules.dart';
import 'tracked_medications.dart';

/// 복용 상태
/// - pending: 예정 (아직 시각 도래 전)
/// - taken: 복용 완료
/// - skipped: 사용자가 건너뜀
/// - missed: 자동 미복용 처리 (예정 시각 + grace 경과)
enum IntakeStatus { pending, taken, skipped, missed }

class IntakeLogs extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// FK → tracked_medications.id. tracked 삭제 시 setNull — 복용 기록은 DB에
  /// 보존하되 origin tracked는 사라짐. 표시용 이름은 [medNameSnapshot].
  /// 변수명은 호환성 위해 medicationId 유지.
  IntColumn get medicationId =>
      integer().nullable().references(TrackedMedications, #id, onDelete: KeyAction.setNull)();

  /// FK → schedules.id. tracked 삭제 시 cascade로 schedules도 사라지므로
  /// 이 FK도 동반 setNull.
  IntColumn get scheduleId =>
      integer().nullable().references(Schedules, #id, onDelete: KeyAction.setNull)();

  /// tracked 삭제 후에도 어떤 약의 기록이었는지 식별할 수 있도록 이름 스냅샷.
  /// [TrackedMedicationRepository.delete] 호출 시점에 tracked.name을 복사.
  /// tracked가 살아 있는 동안엔 null.
  TextColumn get medNameSnapshot => text().nullable()();

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
