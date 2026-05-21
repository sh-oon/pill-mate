import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/tables/catalog_items.dart';

/// 카탈로그(약/영양제 "무엇인지") 저장소.
///
/// 시드 항목과 사용자 추가 항목 둘 다 다룸. 시드 항목은 read-only (편집/삭제 시 throw).
///
/// 본 PR 스코프에서는 검색/조회 기본 API만 제공. 등록 플로우(Phase 3)에서
/// `addUserCustom` + `getById`가 핵심으로 쓰임.
class CatalogRepository {
  CatalogRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  /// 검색어가 비어 있으면 전체. 이름/영문명에서 LIKE 매칭.
  /// 시드 항목을 사용자 항목보다 먼저 노출 (검색 발견성).
  /// 한글 초성 검색은 후속 PR (FTS5).
  Stream<List<CatalogItem>> watchSearch(String query) {
    final stmt = _db.select(_db.catalogItems);
    if (query.isNotEmpty) {
      final pattern = '%${query.replaceAll('%', r'\%')}%';
      stmt.where((c) => c.name.like(pattern) | c.nameEn.like(pattern));
    }
    stmt.orderBy([
      (c) => OrderingTerm(expression: c.source),
      (c) => OrderingTerm(expression: c.name),
    ]);
    return stmt.watch();
  }

  Stream<List<CatalogItem>> watchAll() => watchSearch('');

  Future<CatalogItem?> getById(String id) {
    return (_db.select(_db.catalogItems)..where((c) => c.id.equals(id)))
        .getSingleOrNull();
  }

  /// 사용자가 카탈로그에 없는 항목 직접 추가.
  /// [customId] 미지정 시 UUID v4 자동 발급.
  Future<CatalogItem> addUserCustom({
    required String name,
    required String category,
    String? nameEn,
    String? defaultDosage,
    String? defaultUnit,
    String? shape,
    String? colorHex,
    String? iconKey,
    List<String> tags = const [],
    String? customId,
  }) async {
    final id = customId ?? _uuid.v4();
    await _db.into(_db.catalogItems).insert(
          CatalogItemsCompanion.insert(
            id: id,
            name: name,
            nameEn: Value(nameEn),
            category: category,
            defaultDosage: Value(defaultDosage),
            defaultUnit: Value(defaultUnit),
            shape: Value(shape),
            colorHex: Value(colorHex),
            iconKey: Value(iconKey),
            tagsJson: Value(jsonEncode(tags)),
            source: const Value(CatalogSource.user),
          ),
        );
    return (await getById(id))!;
  }

  /// 사용자 추가 항목만 삭제 가능. 시드 항목 삭제는 [StateError].
  Future<void> deleteUserCustom(String id) async {
    final item = await getById(id);
    if (item == null) return;
    if (item.source != CatalogSource.user) {
      throw StateError('seed catalog item은 삭제할 수 없습니다: $id');
    }
    await (_db.delete(_db.catalogItems)..where((c) => c.id.equals(id))).go();
  }
}

/// 카탈로그 항목 헬퍼 — tagsJson 파싱.
extension CatalogItemX on CatalogItem {
  List<String> get tagList {
    final raw = tagsJson;
    if (raw == null || raw.isEmpty) return const [];
    try {
      return (jsonDecode(raw) as List).cast<String>();
    } catch (_) {
      return const [];
    }
  }
}
