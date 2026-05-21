import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'seed/catalog_seed_loader.dart';
import 'tables/catalog_items.dart';
import 'tables/intake_logs.dart';
import 'tables/interval_occurrences.dart';
import 'tables/medications.dart';
import 'tables/schedules.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    CatalogItems,
    Medications,
    Schedules,
    IntakeLogs,
    IntervalOccurrences,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedCatalogIfEmpty();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // v2: medications.category 컬럼 추가 (nullable text).
            await m.addColumn(medications, medications.category);
          }
          if (from < 3) {
            // v3: interval_occurrences 테이블 신설.
            await m.createTable(intervalOccurrences);
          }
          if (from < 4) {
            // v4: catalog_items 테이블 신설 (additive).
            // 기존 medications/schedules/intake_logs 무변경 — Phase 2에서 FK 연결.
            await m.createTable(catalogItems);
            await _seedCatalogIfEmpty();
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  /// catalog_items가 비어 있으면 번들 시드 JSON에서 INSERT.
  /// 시드 갱신(앱 업데이트 후 신규 시드)은 본 PR 스코프 외 (후속 PR에서 seed_version 기반).
  Future<void> _seedCatalogIfEmpty() async {
    final count = await catalogItems.count().getSingle();
    if (count > 0) return;
    await CatalogSeedLoader(this).loadFromAsset();
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'pill_mate',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }
}
