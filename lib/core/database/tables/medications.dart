import 'package:drift/drift.dart';

class Medications extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 80)();

  /// 'med' (약) | 'sup' (영양제). 카테고리.
  TextColumn get category => text().withLength(max: 8).nullable()();

  TextColumn get dosage => text().withLength(max: 40).nullable()();
  TextColumn get unit => text().withLength(max: 20).nullable()();
  TextColumn get shape => text().withLength(max: 20).nullable()();
  TextColumn get colorHex => text().withLength(min: 7, max: 9).nullable()();
  TextColumn get memo => text().nullable()();
  TextColumn get iconKey => text().withLength(max: 40).nullable()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}
