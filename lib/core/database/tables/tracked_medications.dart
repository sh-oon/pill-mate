import 'package:drift/drift.dart';

import 'catalog_items.dart';

/// 사용자가 "복용 중인" 약/영양제 인스턴스.
///
/// Phase 2C (v7): catalog 메타 중복 컬럼 제거. 표시 정보는 catalog_items가 SSOT.
/// 사용자 override는 customDosage/customUnit nullable로만 보관.
class TrackedMedications extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 카탈로그 항목 FK. nullable: catalog 삭제 시 setNull로 끊긴 legacy 보호.
  /// 신규 등록은 항상 catalog 보장(_resolveOrCreateCatalog).
  TextColumn get catalogItemId =>
      text().references(CatalogItems, #id, onDelete: KeyAction.setNull).nullable()();

  /// catalog.defaultDosage override 전용. null이면 catalog 값 사용.
  TextColumn get customDosage => text().withLength(max: 40).nullable()();

  /// catalog.defaultUnit override 전용. null이면 catalog 값 사용.
  TextColumn get customUnit => text().withLength(max: 20).nullable()();

  /// 사용자 인스턴스 상태.
  TextColumn get memo => text().nullable()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}
