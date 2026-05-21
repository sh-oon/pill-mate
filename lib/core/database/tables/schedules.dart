import 'package:drift/drift.dart';

import 'tracked_medications.dart';

/// 반복 패턴 종류
/// - daily: 매일
/// - weekly: 특정 요일 (daysOfWeek bitmask)
/// - interval: N일마다 (intervalDays)
enum RepeatKind { daily, weekly, interval }

class Schedules extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// FK → tracked_medications.id. 변수명은 호환성 위해 medicationId 유지
  /// (Phase 2B/3에서 trackedMedicationId로 점진 rename).
  IntColumn get medicationId =>
      integer().references(TrackedMedications, #id, onDelete: KeyAction.cascade)();

  /// "HH:mm" 형식 복용 예정 시각 (단일 시각). 여러 시각이 필요하면 행을 복수로.
  TextColumn get timeOfDay => text().withLength(min: 5, max: 5)();

  /// 알림 N분 전 사전 알람 (예: 5분 전). null 이면 사전 알람 없음.
  IntColumn get remindBeforeMinutes => integer().nullable()();

  /// 미복용 시 긴급 재알람 간격(분). null 이면 긴급 알람 비활성.
  IntColumn get urgentRepeatMinutes => integer().nullable()();

  /// 긴급 재알람 최대 반복 횟수 (안전 상한). null 이면 [기본값 사용].
  IntColumn get urgentMaxRepeats => integer().nullable()();

  /// 반복 종류 enum index
  IntColumn get repeatKind =>
      intEnum<RepeatKind>().withDefault(Constant(RepeatKind.daily.index))();

  /// weekly 일 때 요일 bitmask. 비트 0=일요일 ... 비트 6=토요일.
  IntColumn get daysOfWeekMask => integer().nullable()();

  /// interval 일 때 N일.
  IntColumn get intervalDays => integer().nullable()();

  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();

  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}
