import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'tables/intake_logs.dart';
import 'tables/medications.dart';
import 'tables/schedules.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Medications, Schedules, IntakeLogs])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'pill_mate',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }
}
