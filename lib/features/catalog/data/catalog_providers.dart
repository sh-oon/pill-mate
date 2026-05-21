import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import 'catalog_repository.dart';

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepository(ref.watch(appDatabaseProvider));
});

/// 카탈로그 전체 — 등록 플로우 Step 1에서 사용.
final catalogAllProvider = StreamProvider<List<CatalogItem>>((ref) {
  return ref.watch(catalogRepositoryProvider).watchAll();
});

/// 카탈로그 검색 — 검색어 family.
final catalogSearchProvider =
    StreamProvider.family<List<CatalogItem>, String>((ref, query) {
  return ref.watch(catalogRepositoryProvider).watchSearch(query);
});

/// 단일 카탈로그 항목 조회.
final catalogItemByIdProvider =
    FutureProvider.family<CatalogItem?, String>((ref, id) async {
  return ref.watch(catalogRepositoryProvider).getById(id);
});
