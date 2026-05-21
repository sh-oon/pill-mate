import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'seed/catalog_seed_loader.dart';
import 'tables/catalog_items.dart';
import 'tables/intake_logs.dart';
import 'tables/interval_occurrences.dart';
import 'tables/schedules.dart';
import 'tables/tracked_medications.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    CatalogItems,
    TrackedMedications,
    Schedules,
    IntakeLogs,
    IntervalOccurrences,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedCatalogIfEmpty();
        },
        onUpgrade: (m, from, to) async {
          // v5: medications → tracked_medications rename + catalog_item_id FK.
          // 사용자 결정 (catalog-tracking-split plan §C-3): 알파 단계라 전체 wipe.
          // 기존 v1~v4 데이터 모두 삭제 후 신규 스키마로 재생성.
          //
          // schedules/intake_logs/interval_occurrences는 medications FK였으므로
          // 같이 drop. 시드 카탈로그는 재로딩.
          if (from < 5) {
            await customStatement('PRAGMA foreign_keys = OFF');
            await customStatement('DROP TABLE IF EXISTS intake_logs');
            await customStatement('DROP TABLE IF EXISTS interval_occurrences');
            await customStatement('DROP TABLE IF EXISTS schedules');
            await customStatement('DROP TABLE IF EXISTS medications');
            await customStatement('DROP TABLE IF EXISTS catalog_items');
            await customStatement('PRAGMA foreign_keys = ON');
            await m.createAll();
            await _seedCatalogIfEmpty();
            return;
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
