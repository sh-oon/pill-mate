import 'package:drift/drift.dart';

import 'catalog_items.dart';

/// 사용자가 "복용 중인" 약/영양제 인스턴스.
///
/// Phase 2A: medications 테이블에서 이름만 바뀜 + catalog_item_id FK 추가.
/// 카탈로그 메타 컬럼(name/category/dosage/...)은 Phase 2B에서 catalog_items로
/// 이주 예정. 그동안 이중 보관.
class TrackedMedications extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 카탈로그 항목 FK. nullable: 마이그레이션 이전 데이터/직접 입력 경로.
  /// 카탈로그 항목 삭제 시 setNull (사용자 tracked는 남되 카탈로그 연결만 끊김).
  TextColumn get catalogItemId =>
      text().references(CatalogItems, #id, onDelete: KeyAction.setNull).nullable()();

  // ── 이하 medications 테이블에서 그대로 이주 (Phase 2B에서 정리) ──
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
