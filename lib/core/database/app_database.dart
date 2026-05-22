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
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          // v8: catalog ↔ tracked 1:1 보장용 partial UNIQUE INDEX. NULL은 다중
          // 허용해 legacy catalog 끊김 보호. 신규 설치도 동일 제약 적용.
          await customStatement(
              'CREATE UNIQUE INDEX IF NOT EXISTS '
              'idx_tracked_meds_catalog_unique '
              'ON tracked_medications(catalog_item_id) '
              'WHERE catalog_item_id IS NOT NULL');
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

          // v6: intake_logs FK cascade → setNull. tracked 삭제해도 기록 보존.
          // medNameSnapshot 컬럼 추가. SQLite는 FK constraint를 ALTER TABLE로
          // 변경 못 하므로 표준 패턴: 새 테이블 만들고 복사 후 swap.
          if (from < 6) {
            await customStatement('PRAGMA foreign_keys = OFF');
            await customStatement('''
              CREATE TABLE intake_logs_new (
                id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
                medication_id INTEGER NULL
                  REFERENCES tracked_medications(id) ON DELETE SET NULL,
                schedule_id INTEGER NULL
                  REFERENCES schedules(id) ON DELETE SET NULL,
                med_name_snapshot TEXT NULL,
                scheduled_at INTEGER NOT NULL,
                acted_at INTEGER NULL,
                status INTEGER NOT NULL DEFAULT 0,
                urgent_fired_count INTEGER NOT NULL DEFAULT 0,
                memo TEXT NULL,
                created_at INTEGER NOT NULL DEFAULT (strftime('%s','now')),
                updated_at INTEGER NOT NULL DEFAULT (strftime('%s','now'))
              )
            ''');
            await customStatement('''
              INSERT INTO intake_logs_new
                (id, medication_id, schedule_id, med_name_snapshot,
                 scheduled_at, acted_at, status, urgent_fired_count, memo,
                 created_at, updated_at)
              SELECT
                id, medication_id, schedule_id, NULL,
                scheduled_at, acted_at, status, urgent_fired_count, memo,
                created_at, updated_at
              FROM intake_logs
            ''');
            await customStatement('DROP TABLE intake_logs');
            await customStatement(
                'ALTER TABLE intake_logs_new RENAME TO intake_logs');
            await customStatement('PRAGMA foreign_keys = ON');
          }

          // v7: tracked_medications에서 catalog 중복 메타 컬럼 drop.
          //   - drop: name, category, shape, color_hex, icon_key
          //   - rename: dosage → custom_dosage, unit → custom_unit
          //   - 백필: tracked 메타를 catalog로 끌어올림 + (name, category) dedupe
          //   - override는 catalog.default_*와 다를 때만 보존 → 동일하면 NULL로
          //     비워 catalog 갱신 자동 반영.
          if (from < 7) {
            await customStatement('PRAGMA foreign_keys = OFF');

            // (1) 백필: tracked.catalog_item_id IS NULL이고 매칭 catalog가 없는
            //     경우 user-source catalog 자동 생성. seed는 절대 안 만짐.
            await customStatement('''
              INSERT INTO catalog_items
                (id, name, category, default_dosage, default_unit, shape,
                 color_hex, icon_key, tags_json, source, created_at)
              SELECT
                lower(hex(randomblob(16))),
                t.name,
                COALESCE(t.category, 'sup'),
                t.dosage,
                t.unit,
                t.shape,
                t.color_hex,
                t.icon_key,
                NULL,
                1,
                strftime('%s','now')
              FROM tracked_medications t
              WHERE t.catalog_item_id IS NULL
                AND NOT EXISTS (
                  SELECT 1 FROM catalog_items c
                  WHERE c.name = t.name
                    AND c.category = COALESCE(t.category, 'sup')
                )
            ''');

            // (2) catalog_item_id NULL인 tracked에 catalog 연결.
            //     seed 우선(source=0), 그 다음 created_at 오래된 순.
            await customStatement('''
              UPDATE tracked_medications
                 SET catalog_item_id = (
                       SELECT c.id FROM catalog_items c
                        WHERE c.name = tracked_medications.name
                          AND c.category = COALESCE(tracked_medications.category, 'sup')
                        ORDER BY (c.source = 0) DESC,
                                 c.created_at ASC
                        LIMIT 1
                     )
               WHERE catalog_item_id IS NULL
            ''');

            // (3) 신규 테이블 — 메타 컬럼 제거 + override rename.
            await customStatement('''
              CREATE TABLE tracked_medications_new (
                id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
                catalog_item_id TEXT NULL
                  REFERENCES catalog_items(id) ON DELETE SET NULL,
                custom_dosage TEXT NULL,
                custom_unit TEXT NULL,
                memo TEXT NULL,
                archived INTEGER NOT NULL DEFAULT 0,
                created_at INTEGER NOT NULL DEFAULT (strftime('%s','now')),
                updated_at INTEGER NOT NULL DEFAULT (strftime('%s','now'))
              )
            ''');

            // (4) 데이터 복사 — catalog.default_*와 같으면 override NULL로.
            await customStatement('''
              INSERT INTO tracked_medications_new
                (id, catalog_item_id, custom_dosage, custom_unit, memo,
                 archived, created_at, updated_at)
              SELECT
                t.id,
                t.catalog_item_id,
                CASE
                  WHEN t.dosage IS NOT NULL
                   AND t.dosage != COALESCE(c.default_dosage, '')
                  THEN t.dosage
                  ELSE NULL
                END,
                CASE
                  WHEN t.unit IS NOT NULL
                   AND t.unit != COALESCE(c.default_unit, '')
                  THEN t.unit
                  ELSE NULL
                END,
                t.memo,
                t.archived,
                t.created_at,
                t.updated_at
              FROM tracked_medications t
              LEFT JOIN catalog_items c ON c.id = t.catalog_item_id
            ''');

            // (5) swap.
            await customStatement('DROP TABLE tracked_medications');
            await customStatement(
                'ALTER TABLE tracked_medications_new '
                'RENAME TO tracked_medications');

            // (6) 인덱스 재생성.
            await customStatement(
                'CREATE INDEX IF NOT EXISTS idx_tracked_meds_archived '
                'ON tracked_medications(archived)');
            await customStatement(
                'CREATE INDEX IF NOT EXISTS idx_tracked_meds_catalog '
                'ON tracked_medications(catalog_item_id)');

            await customStatement('PRAGMA foreign_keys = ON');
          }

          // v8: catalog ↔ tracked 1:1 정규화.
          //   - 같은 catalog의 tracked가 여러 행이면 MIN(id) survivor로 통합.
          //   - 비-survivor의 schedules/intake_logs를 survivor로 재link 후
          //     비-survivor 행 삭제.
          //   - 그 다음 schedules (medication_id, time_of_day) 중복 제거.
          //   - 마지막으로 catalog_item_id에 partial UNIQUE INDEX 부여
          //     (NULL은 다중 허용 — legacy catalog 끊긴 행 보호).
          if (from < 8) {
            await customStatement('PRAGMA foreign_keys = OFF');

            // (1) schedules의 medication_id를 비-survivor → survivor로 재link.
            await customStatement('''
              UPDATE schedules
                 SET medication_id = (
                       SELECT MIN(t2.id) FROM tracked_medications t2
                        WHERE t2.catalog_item_id = (
                              SELECT t1.catalog_item_id
                                FROM tracked_medications t1
                               WHERE t1.id = schedules.medication_id
                              )
                     )
               WHERE medication_id IN (
                     SELECT t.id FROM tracked_medications t
                      WHERE t.catalog_item_id IS NOT NULL
                        AND t.id != (
                              SELECT MIN(t2.id) FROM tracked_medications t2
                               WHERE t2.catalog_item_id = t.catalog_item_id
                            )
                     )
            ''');

            // (2) intake_logs의 medication_id를 비-survivor → survivor로 재link.
            //     scheduleId는 (1)에서 schedules가 survivor 소속이 됐으니 그대로 OK.
            await customStatement('''
              UPDATE intake_logs
                 SET medication_id = (
                       SELECT MIN(t2.id) FROM tracked_medications t2
                        WHERE t2.catalog_item_id = (
                              SELECT t1.catalog_item_id
                                FROM tracked_medications t1
                               WHERE t1.id = intake_logs.medication_id
                              )
                     )
               WHERE medication_id IN (
                     SELECT t.id FROM tracked_medications t
                      WHERE t.catalog_item_id IS NOT NULL
                        AND t.id != (
                              SELECT MIN(t2.id) FROM tracked_medications t2
                               WHERE t2.catalog_item_id = t.catalog_item_id
                            )
                     )
            ''');

            // (3) 비-survivor tracked 행 삭제.
            await customStatement('''
              DELETE FROM tracked_medications
               WHERE catalog_item_id IS NOT NULL
                 AND id != (
                       SELECT MIN(t2.id) FROM tracked_medications t2
                        WHERE t2.catalog_item_id = tracked_medications.catalog_item_id
                     )
            ''');

            // (4) schedules (medication_id, time_of_day) 중복 정리 — MIN(id) 보존.
            //     (1)에서 다른 tracked의 같은 시각 schedule이 survivor 소속으로
            //     옮겨와 같은 medication_id에 중복이 생길 수 있음.
            await customStatement('''
              DELETE FROM schedules
               WHERE id NOT IN (
                     SELECT MIN(id) FROM schedules
                      GROUP BY medication_id, time_of_day
                     )
            ''');

            // (5) catalog_item_id partial UNIQUE INDEX — NULL은 다중 허용.
            //     기존 non-unique idx_tracked_meds_catalog는 그대로 두어도
            //     UNIQUE가 우선하지만, 의도 명확화 위해 drop 후 재생성.
            await customStatement(
                'DROP INDEX IF EXISTS idx_tracked_meds_catalog');
            await customStatement(
                'CREATE UNIQUE INDEX IF NOT EXISTS '
                'idx_tracked_meds_catalog_unique '
                'ON tracked_medications(catalog_item_id) '
                'WHERE catalog_item_id IS NOT NULL');

            await customStatement('PRAGMA foreign_keys = ON');
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
