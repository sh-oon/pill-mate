// ignore_for_file: avoid_print
//
// 시드 카탈로그 JSON 스키마 검증 도구.
//
// 사용:
//   dart run tool/validate_seed_catalog.dart
//
// CI에서 .github/workflows/ci.yml의 analyze-and-test job에서 실행됨.
// 검증 실패 시 exit code != 0.

import 'dart:convert';
import 'dart:io';

const _assetPath = 'assets/seed/catalog_supplements.ko.json';

const _allowedCategories = {'med', 'sup'};

const _allowedShapes = {
  'tablet',
  'capsule',
  'softgel',
  'powder',
  'liquid',
  'gummy',
  'sachet',
};

const _allowedIconKeys = {
  'pill',
  'capsule',
  'tablet',
  'softgel',
  'powder',
  'liquid',
};

final _slugRegex = RegExp(r'^[a-z0-9][a-z0-9\-]+$');
final _hexRegex = RegExp(r'^#[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?$');

Future<void> main() async {
  final file = File(_assetPath);
  if (!await file.exists()) {
    print('⚠️  $_assetPath not found. Skipping seed validation.');
    print('   (시드 큐레이션이 별도 진행 중일 수 있음 — 빌드 실패는 아님)');
    exit(0);
  }

  final raw = await file.readAsString();
  final Map<String, dynamic> json;
  try {
    json = jsonDecode(raw) as Map<String, dynamic>;
  } catch (e) {
    _fail('JSON 파싱 실패: $e');
  }

  if (json['version'] is! int) {
    _fail('top-level "version" must be int');
  }

  final items = json['items'];
  if (items is! List) {
    _fail('top-level "items" must be a list');
  }

  final ids = <String>{};
  var errors = 0;

  for (var i = 0; i < items.length; i++) {
    final raw = items[i];
    if (raw is! Map<String, dynamic>) {
      print('❌  items[$i] not a map');
      errors++;
      continue;
    }
    errors += _validateItem(i, raw, ids);
  }

  if (errors > 0) {
    _fail('총 $errors 건의 시드 카탈로그 검증 오류');
  }

  print('✓ 시드 카탈로그 검증 통과 (${items.length}개)');
}

int _validateItem(int idx, Map<String, dynamic> item, Set<String> ids) {
  var errors = 0;

  String? errPrefix(String field) => '❌  items[$idx].$field';

  // id
  final id = item['id'];
  if (id is! String || !_slugRegex.hasMatch(id)) {
    print('${errPrefix('id')}: invalid slug "$id"');
    errors++;
  } else if (!ids.add(id)) {
    print('${errPrefix('id')}: duplicate "$id"');
    errors++;
  }

  // name
  final name = item['name'];
  if (name is! String || name.isEmpty || name.length > 80) {
    print('${errPrefix('name')}: invalid "$name"');
    errors++;
  }

  // category
  final category = item['category'];
  if (category is! String || !_allowedCategories.contains(category)) {
    print('${errPrefix('category')}: must be one of $_allowedCategories, got "$category"');
    errors++;
  }

  // shape (nullable)
  final shape = item['shape'];
  if (shape != null && (shape is! String || !_allowedShapes.contains(shape))) {
    print('${errPrefix('shape')}: must be one of $_allowedShapes or null, got "$shape"');
    errors++;
  }

  // iconKey (nullable)
  final iconKey = item['iconKey'];
  if (iconKey != null &&
      (iconKey is! String || !_allowedIconKeys.contains(iconKey))) {
    print('${errPrefix('iconKey')}: must be one of $_allowedIconKeys or null, got "$iconKey"');
    errors++;
  }

  // colorHex (nullable)
  final colorHex = item['colorHex'];
  if (colorHex != null &&
      (colorHex is! String || !_hexRegex.hasMatch(colorHex))) {
    print('${errPrefix('colorHex')}: invalid hex "$colorHex"');
    errors++;
  }

  // tags (nullable list of strings)
  final tags = item['tags'];
  if (tags != null) {
    if (tags is! List) {
      print('${errPrefix('tags')}: must be a list');
      errors++;
    } else {
      for (final t in tags) {
        if (t is! String || t.isEmpty) {
          print('${errPrefix('tags')}: non-empty string only, got "$t"');
          errors++;
        }
      }
    }
  }

  return errors;
}

Never _fail(String msg) {
  print('❌  $msg');
  exit(1);
}
