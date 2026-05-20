import 'package:drift/drift.dart';

import 'schedules.dart';

/// N일 간격(interval) 반복 스케줄의 미래 발생 큐.
///
/// OS의 `matchDateTimeComponents`로 N일 간격 표현 불가하므로, 각 발생을
/// 단발 알림으로 등록하고 그 시각을 여기 보관. 사용자 액션 후 큐 길이를
/// 보강(`ensureQueueFor`)해서 미래 7~14일분을 항상 유지.
class IntervalOccurrences extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get scheduleId =>
      integer().references(Schedules, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get scheduledAt => dateTime()();
  BoolColumn get notified => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}
