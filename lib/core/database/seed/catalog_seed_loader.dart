import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../app_database.dart';
import '../tables/catalog_items.dart';

/// 앱 번들에 포함된 시드 카탈로그 JSON을 읽어 `catalog_items`에 INSERT.
///
/// 호출 정책: `AppDatabase._seedCatalogIfEmpty`에서 catalog_items가 비어 있을 때만.
/// 시드 갱신 (앱 업데이트 후 신규 시드 받기)은 본 PR 스코프 외, 후속 PR에서 처리.
class CatalogSeedLoader {
  CatalogSeedLoader(this._db);
  final AppDatabase _db;

  static const String defaultAssetPath =
      'assets/seed/catalog_supplements.ko.json';

  /// [assetPath]의 JSON을 읽어 `catalog_items`에 INSERT (insertOrIgnore — 중복 시 skip).
  /// 자산이 없거나 JSON이 깨졌으면 경고 출력 후 무시 (앱 부팅을 막지 않음).
  Future<int> loadFromAsset({String assetPath = defaultAssetPath}) async {
    final String raw;
    try {
      raw = await rootBundle.loadString(assetPath);
    } catch (e) {
      debugPrint('CatalogSeedLoader: asset $assetPath 로드 실패: $e');
      return 0;
    }

    final List<Map<String, dynamic>> items;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      items = (json['items'] as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('CatalogSeedLoader: $assetPath 파싱 실패: $e');
      return 0;
    }

    if (items.isEmpty) return 0;

    var inserted = 0;
    await _db.batch((batch) {
      for (final item in items) {
        final tags = (item['tags'] as List?)?.cast<String>() ?? const [];
        batch.insert(
          _db.catalogItems,
          CatalogItemsCompanion.insert(
            id: item['id'] as String,
            name: item['name'] as String,
            nameEn: Value(item['name_en'] as String?),
            category: item['category'] as String,
            defaultDosage: Value(item['default_dosage'] as String?),
            defaultUnit: Value(item['default_unit'] as String?),
            shape: Value(item['shape'] as String?),
            colorHex: Value(item['colorHex'] as String?),
            iconKey: Value(item['iconKey'] as String?),
            tagsJson: Value(jsonEncode(tags)),
            source: Value(CatalogSource.seed),
          ),
          mode: InsertMode.insertOrIgnore,
        );
        inserted++;
      }
    });

    if (kDebugMode) {
      debugPrint('CatalogSeedLoader: 시드 카탈로그 $inserted개 시도 (insertOrIgnore)');
    }
    return inserted;
  }
}
