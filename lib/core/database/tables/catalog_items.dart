import 'package:drift/drift.dart';

/// 카탈로그 항목 출처.
/// - seed: 앱 번들 JSON에서 로드된 항목 (read-only, 시드 갱신 정책 따라 갱신)
/// - user: 사용자가 직접 추가한 항목 (편집/삭제 가능)
enum CatalogSource { seed, user }

/// 약/영양제 카탈로그 — "무엇인지" 정의.
///
/// 시드(번들) 항목과 사용자 직접 추가 항목이 한 테이블에 공존.
/// 시드 항목은 [id]가 슬러그(`vit-d3-1000iu`), 사용자 항목은 UUID v4.
class CatalogItems extends Table {
  /// 슬러그 또는 UUID. 예: 'vit-d3-1000iu', 'a1b2c3d4-...'
  /// TEXT primary key — INT autoinc가 아닌 이유: 시드 안정성 (앱 업데이트 시
  /// 행 번호 재할당 무관, 외부 참조 안전).
  TextColumn get id => text().withLength(min: 1, max: 64)();

  TextColumn get name => text().withLength(min: 1, max: 80)();
  TextColumn get nameEn => text().withLength(max: 80).nullable()();

  /// 'med' (약) | 'sup' (영양제). 기존 medications.category와 동일 enum.
  TextColumn get category => text().withLength(max: 8)();

  /// 기본 용량 표기. 시드 큐레이션 값. 사용자 인스턴스에서 override 가능 (Phase 2).
  TextColumn get defaultDosage => text().withLength(max: 40).nullable()();
  TextColumn get defaultUnit => text().withLength(max: 20).nullable()();

  /// 형태. 'tablet' | 'capsule' | 'softgel' | 'powder' | 'liquid' | 'gummy' | 'sachet'
  TextColumn get shape => text().withLength(max: 20).nullable()();

  /// 표시 색상. #RRGGBB 또는 #AARRGGBB.
  TextColumn get colorHex => text().withLength(min: 7, max: 9).nullable()();

  /// 아이콘 키. 'pill' | 'capsule' | 'tablet' | 'softgel' | 'powder' | 'liquid'
  TextColumn get iconKey => text().withLength(max: 40).nullable()();

  /// JSON-encoded `List<String>`. 예: '["면역","뼈건강"]'.
  /// SQLite는 TEXT로 저장, 앱에서 jsonDecode/jsonEncode.
  TextColumn get tagsJson => text().nullable()();

  /// CatalogSource enum index.
  IntColumn get source =>
      intEnum<CatalogSource>().withDefault(Constant(CatalogSource.user.index))();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
