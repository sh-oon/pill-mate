// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $MedicationsTable extends Medications
    with TableInfo<$MedicationsTable, Medication> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MedicationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 80,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 8),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dosageMeta = const VerificationMeta('dosage');
  @override
  late final GeneratedColumn<String> dosage = GeneratedColumn<String>(
    'dosage',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 40),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 20),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _shapeMeta = const VerificationMeta('shape');
  @override
  late final GeneratedColumn<String> shape = GeneratedColumn<String>(
    'shape',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 20),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorHexMeta = const VerificationMeta(
    'colorHex',
  );
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
    'color_hex',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 7,
      maxTextLength: 9,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _memoMeta = const VerificationMeta('memo');
  @override
  late final GeneratedColumn<String> memo = GeneratedColumn<String>(
    'memo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _iconKeyMeta = const VerificationMeta(
    'iconKey',
  );
  @override
  late final GeneratedColumn<String> iconKey = GeneratedColumn<String>(
    'icon_key',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 40),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    category,
    dosage,
    unit,
    shape,
    colorHex,
    memo,
    iconKey,
    archived,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'medications';
  @override
  VerificationContext validateIntegrity(
    Insertable<Medication> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('dosage')) {
      context.handle(
        _dosageMeta,
        dosage.isAcceptableOrUnknown(data['dosage']!, _dosageMeta),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('shape')) {
      context.handle(
        _shapeMeta,
        shape.isAcceptableOrUnknown(data['shape']!, _shapeMeta),
      );
    }
    if (data.containsKey('color_hex')) {
      context.handle(
        _colorHexMeta,
        colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta),
      );
    }
    if (data.containsKey('memo')) {
      context.handle(
        _memoMeta,
        memo.isAcceptableOrUnknown(data['memo']!, _memoMeta),
      );
    }
    if (data.containsKey('icon_key')) {
      context.handle(
        _iconKeyMeta,
        iconKey.isAcceptableOrUnknown(data['icon_key']!, _iconKeyMeta),
      );
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Medication map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Medication(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      dosage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dosage'],
      ),
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      ),
      shape: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shape'],
      ),
      colorHex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_hex'],
      ),
      memo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}memo'],
      ),
      iconKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_key'],
      ),
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $MedicationsTable createAlias(String alias) {
    return $MedicationsTable(attachedDatabase, alias);
  }
}

class Medication extends DataClass implements Insertable<Medication> {
  final int id;
  final String name;

  /// 'med' (약) | 'sup' (영양제). 카테고리.
  final String? category;
  final String? dosage;
  final String? unit;
  final String? shape;
  final String? colorHex;
  final String? memo;
  final String? iconKey;
  final bool archived;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Medication({
    required this.id,
    required this.name,
    this.category,
    this.dosage,
    this.unit,
    this.shape,
    this.colorHex,
    this.memo,
    this.iconKey,
    required this.archived,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    if (!nullToAbsent || dosage != null) {
      map['dosage'] = Variable<String>(dosage);
    }
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    if (!nullToAbsent || shape != null) {
      map['shape'] = Variable<String>(shape);
    }
    if (!nullToAbsent || colorHex != null) {
      map['color_hex'] = Variable<String>(colorHex);
    }
    if (!nullToAbsent || memo != null) {
      map['memo'] = Variable<String>(memo);
    }
    if (!nullToAbsent || iconKey != null) {
      map['icon_key'] = Variable<String>(iconKey);
    }
    map['archived'] = Variable<bool>(archived);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MedicationsCompanion toCompanion(bool nullToAbsent) {
    return MedicationsCompanion(
      id: Value(id),
      name: Value(name),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      dosage: dosage == null && nullToAbsent
          ? const Value.absent()
          : Value(dosage),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      shape: shape == null && nullToAbsent
          ? const Value.absent()
          : Value(shape),
      colorHex: colorHex == null && nullToAbsent
          ? const Value.absent()
          : Value(colorHex),
      memo: memo == null && nullToAbsent ? const Value.absent() : Value(memo),
      iconKey: iconKey == null && nullToAbsent
          ? const Value.absent()
          : Value(iconKey),
      archived: Value(archived),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Medication.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Medication(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      category: serializer.fromJson<String?>(json['category']),
      dosage: serializer.fromJson<String?>(json['dosage']),
      unit: serializer.fromJson<String?>(json['unit']),
      shape: serializer.fromJson<String?>(json['shape']),
      colorHex: serializer.fromJson<String?>(json['colorHex']),
      memo: serializer.fromJson<String?>(json['memo']),
      iconKey: serializer.fromJson<String?>(json['iconKey']),
      archived: serializer.fromJson<bool>(json['archived']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'category': serializer.toJson<String?>(category),
      'dosage': serializer.toJson<String?>(dosage),
      'unit': serializer.toJson<String?>(unit),
      'shape': serializer.toJson<String?>(shape),
      'colorHex': serializer.toJson<String?>(colorHex),
      'memo': serializer.toJson<String?>(memo),
      'iconKey': serializer.toJson<String?>(iconKey),
      'archived': serializer.toJson<bool>(archived),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Medication copyWith({
    int? id,
    String? name,
    Value<String?> category = const Value.absent(),
    Value<String?> dosage = const Value.absent(),
    Value<String?> unit = const Value.absent(),
    Value<String?> shape = const Value.absent(),
    Value<String?> colorHex = const Value.absent(),
    Value<String?> memo = const Value.absent(),
    Value<String?> iconKey = const Value.absent(),
    bool? archived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Medication(
    id: id ?? this.id,
    name: name ?? this.name,
    category: category.present ? category.value : this.category,
    dosage: dosage.present ? dosage.value : this.dosage,
    unit: unit.present ? unit.value : this.unit,
    shape: shape.present ? shape.value : this.shape,
    colorHex: colorHex.present ? colorHex.value : this.colorHex,
    memo: memo.present ? memo.value : this.memo,
    iconKey: iconKey.present ? iconKey.value : this.iconKey,
    archived: archived ?? this.archived,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Medication copyWithCompanion(MedicationsCompanion data) {
    return Medication(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      category: data.category.present ? data.category.value : this.category,
      dosage: data.dosage.present ? data.dosage.value : this.dosage,
      unit: data.unit.present ? data.unit.value : this.unit,
      shape: data.shape.present ? data.shape.value : this.shape,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
      memo: data.memo.present ? data.memo.value : this.memo,
      iconKey: data.iconKey.present ? data.iconKey.value : this.iconKey,
      archived: data.archived.present ? data.archived.value : this.archived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Medication(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('dosage: $dosage, ')
          ..write('unit: $unit, ')
          ..write('shape: $shape, ')
          ..write('colorHex: $colorHex, ')
          ..write('memo: $memo, ')
          ..write('iconKey: $iconKey, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    category,
    dosage,
    unit,
    shape,
    colorHex,
    memo,
    iconKey,
    archived,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Medication &&
          other.id == this.id &&
          other.name == this.name &&
          other.category == this.category &&
          other.dosage == this.dosage &&
          other.unit == this.unit &&
          other.shape == this.shape &&
          other.colorHex == this.colorHex &&
          other.memo == this.memo &&
          other.iconKey == this.iconKey &&
          other.archived == this.archived &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class MedicationsCompanion extends UpdateCompanion<Medication> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> category;
  final Value<String?> dosage;
  final Value<String?> unit;
  final Value<String?> shape;
  final Value<String?> colorHex;
  final Value<String?> memo;
  final Value<String?> iconKey;
  final Value<bool> archived;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const MedicationsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.category = const Value.absent(),
    this.dosage = const Value.absent(),
    this.unit = const Value.absent(),
    this.shape = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.memo = const Value.absent(),
    this.iconKey = const Value.absent(),
    this.archived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  MedicationsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.category = const Value.absent(),
    this.dosage = const Value.absent(),
    this.unit = const Value.absent(),
    this.shape = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.memo = const Value.absent(),
    this.iconKey = const Value.absent(),
    this.archived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Medication> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? category,
    Expression<String>? dosage,
    Expression<String>? unit,
    Expression<String>? shape,
    Expression<String>? colorHex,
    Expression<String>? memo,
    Expression<String>? iconKey,
    Expression<bool>? archived,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (category != null) 'category': category,
      if (dosage != null) 'dosage': dosage,
      if (unit != null) 'unit': unit,
      if (shape != null) 'shape': shape,
      if (colorHex != null) 'color_hex': colorHex,
      if (memo != null) 'memo': memo,
      if (iconKey != null) 'icon_key': iconKey,
      if (archived != null) 'archived': archived,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  MedicationsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? category,
    Value<String?>? dosage,
    Value<String?>? unit,
    Value<String?>? shape,
    Value<String?>? colorHex,
    Value<String?>? memo,
    Value<String?>? iconKey,
    Value<bool>? archived,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return MedicationsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      dosage: dosage ?? this.dosage,
      unit: unit ?? this.unit,
      shape: shape ?? this.shape,
      colorHex: colorHex ?? this.colorHex,
      memo: memo ?? this.memo,
      iconKey: iconKey ?? this.iconKey,
      archived: archived ?? this.archived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (dosage.present) {
      map['dosage'] = Variable<String>(dosage.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (shape.present) {
      map['shape'] = Variable<String>(shape.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (memo.present) {
      map['memo'] = Variable<String>(memo.value);
    }
    if (iconKey.present) {
      map['icon_key'] = Variable<String>(iconKey.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MedicationsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('dosage: $dosage, ')
          ..write('unit: $unit, ')
          ..write('shape: $shape, ')
          ..write('colorHex: $colorHex, ')
          ..write('memo: $memo, ')
          ..write('iconKey: $iconKey, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $SchedulesTable extends Schedules
    with TableInfo<$SchedulesTable, Schedule> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SchedulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _medicationIdMeta = const VerificationMeta(
    'medicationId',
  );
  @override
  late final GeneratedColumn<int> medicationId = GeneratedColumn<int>(
    'medication_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES medications (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _timeOfDayMeta = const VerificationMeta(
    'timeOfDay',
  );
  @override
  late final GeneratedColumn<String> timeOfDay = GeneratedColumn<String>(
    'time_of_day',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 5,
      maxTextLength: 5,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remindBeforeMinutesMeta =
      const VerificationMeta('remindBeforeMinutes');
  @override
  late final GeneratedColumn<int> remindBeforeMinutes = GeneratedColumn<int>(
    'remind_before_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _urgentRepeatMinutesMeta =
      const VerificationMeta('urgentRepeatMinutes');
  @override
  late final GeneratedColumn<int> urgentRepeatMinutes = GeneratedColumn<int>(
    'urgent_repeat_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _urgentMaxRepeatsMeta = const VerificationMeta(
    'urgentMaxRepeats',
  );
  @override
  late final GeneratedColumn<int> urgentMaxRepeats = GeneratedColumn<int>(
    'urgent_max_repeats',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<RepeatKind, int> repeatKind =
      GeneratedColumn<int>(
        'repeat_kind',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: Constant(RepeatKind.daily.index),
      ).withConverter<RepeatKind>($SchedulesTable.$converterrepeatKind);
  static const VerificationMeta _daysOfWeekMaskMeta = const VerificationMeta(
    'daysOfWeekMask',
  );
  @override
  late final GeneratedColumn<int> daysOfWeekMask = GeneratedColumn<int>(
    'days_of_week_mask',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _intervalDaysMeta = const VerificationMeta(
    'intervalDays',
  );
  @override
  late final GeneratedColumn<int> intervalDays = GeneratedColumn<int>(
    'interval_days',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
    'end_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    medicationId,
    timeOfDay,
    remindBeforeMinutes,
    urgentRepeatMinutes,
    urgentMaxRepeats,
    repeatKind,
    daysOfWeekMask,
    intervalDays,
    startDate,
    endDate,
    enabled,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'schedules';
  @override
  VerificationContext validateIntegrity(
    Insertable<Schedule> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('medication_id')) {
      context.handle(
        _medicationIdMeta,
        medicationId.isAcceptableOrUnknown(
          data['medication_id']!,
          _medicationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_medicationIdMeta);
    }
    if (data.containsKey('time_of_day')) {
      context.handle(
        _timeOfDayMeta,
        timeOfDay.isAcceptableOrUnknown(data['time_of_day']!, _timeOfDayMeta),
      );
    } else if (isInserting) {
      context.missing(_timeOfDayMeta);
    }
    if (data.containsKey('remind_before_minutes')) {
      context.handle(
        _remindBeforeMinutesMeta,
        remindBeforeMinutes.isAcceptableOrUnknown(
          data['remind_before_minutes']!,
          _remindBeforeMinutesMeta,
        ),
      );
    }
    if (data.containsKey('urgent_repeat_minutes')) {
      context.handle(
        _urgentRepeatMinutesMeta,
        urgentRepeatMinutes.isAcceptableOrUnknown(
          data['urgent_repeat_minutes']!,
          _urgentRepeatMinutesMeta,
        ),
      );
    }
    if (data.containsKey('urgent_max_repeats')) {
      context.handle(
        _urgentMaxRepeatsMeta,
        urgentMaxRepeats.isAcceptableOrUnknown(
          data['urgent_max_repeats']!,
          _urgentMaxRepeatsMeta,
        ),
      );
    }
    if (data.containsKey('days_of_week_mask')) {
      context.handle(
        _daysOfWeekMaskMeta,
        daysOfWeekMask.isAcceptableOrUnknown(
          data['days_of_week_mask']!,
          _daysOfWeekMaskMeta,
        ),
      );
    }
    if (data.containsKey('interval_days')) {
      context.handle(
        _intervalDaysMeta,
        intervalDays.isAcceptableOrUnknown(
          data['interval_days']!,
          _intervalDaysMeta,
        ),
      );
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Schedule map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Schedule(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      medicationId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}medication_id'],
      )!,
      timeOfDay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time_of_day'],
      )!,
      remindBeforeMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}remind_before_minutes'],
      ),
      urgentRepeatMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}urgent_repeat_minutes'],
      ),
      urgentMaxRepeats: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}urgent_max_repeats'],
      ),
      repeatKind: $SchedulesTable.$converterrepeatKind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}repeat_kind'],
        )!,
      ),
      daysOfWeekMask: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}days_of_week_mask'],
      ),
      intervalDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_days'],
      ),
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      )!,
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_date'],
      ),
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SchedulesTable createAlias(String alias) {
    return $SchedulesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<RepeatKind, int, int> $converterrepeatKind =
      const EnumIndexConverter<RepeatKind>(RepeatKind.values);
}

class Schedule extends DataClass implements Insertable<Schedule> {
  final int id;
  final int medicationId;

  /// "HH:mm" 형식 복용 예정 시각 (단일 시각). 여러 시각이 필요하면 행을 복수로.
  final String timeOfDay;

  /// 알림 N분 전 사전 알람 (예: 5분 전). null 이면 사전 알람 없음.
  final int? remindBeforeMinutes;

  /// 미복용 시 긴급 재알람 간격(분). null 이면 긴급 알람 비활성.
  final int? urgentRepeatMinutes;

  /// 긴급 재알람 최대 반복 횟수 (안전 상한). null 이면 [기본값 사용].
  final int? urgentMaxRepeats;

  /// 반복 종류 enum index
  final RepeatKind repeatKind;

  /// weekly 일 때 요일 bitmask. 비트 0=일요일 ... 비트 6=토요일.
  final int? daysOfWeekMask;

  /// interval 일 때 N일.
  final int? intervalDays;
  final DateTime startDate;
  final DateTime? endDate;
  final bool enabled;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Schedule({
    required this.id,
    required this.medicationId,
    required this.timeOfDay,
    this.remindBeforeMinutes,
    this.urgentRepeatMinutes,
    this.urgentMaxRepeats,
    required this.repeatKind,
    this.daysOfWeekMask,
    this.intervalDays,
    required this.startDate,
    this.endDate,
    required this.enabled,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['medication_id'] = Variable<int>(medicationId);
    map['time_of_day'] = Variable<String>(timeOfDay);
    if (!nullToAbsent || remindBeforeMinutes != null) {
      map['remind_before_minutes'] = Variable<int>(remindBeforeMinutes);
    }
    if (!nullToAbsent || urgentRepeatMinutes != null) {
      map['urgent_repeat_minutes'] = Variable<int>(urgentRepeatMinutes);
    }
    if (!nullToAbsent || urgentMaxRepeats != null) {
      map['urgent_max_repeats'] = Variable<int>(urgentMaxRepeats);
    }
    {
      map['repeat_kind'] = Variable<int>(
        $SchedulesTable.$converterrepeatKind.toSql(repeatKind),
      );
    }
    if (!nullToAbsent || daysOfWeekMask != null) {
      map['days_of_week_mask'] = Variable<int>(daysOfWeekMask);
    }
    if (!nullToAbsent || intervalDays != null) {
      map['interval_days'] = Variable<int>(intervalDays);
    }
    map['start_date'] = Variable<DateTime>(startDate);
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<DateTime>(endDate);
    }
    map['enabled'] = Variable<bool>(enabled);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SchedulesCompanion toCompanion(bool nullToAbsent) {
    return SchedulesCompanion(
      id: Value(id),
      medicationId: Value(medicationId),
      timeOfDay: Value(timeOfDay),
      remindBeforeMinutes: remindBeforeMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(remindBeforeMinutes),
      urgentRepeatMinutes: urgentRepeatMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(urgentRepeatMinutes),
      urgentMaxRepeats: urgentMaxRepeats == null && nullToAbsent
          ? const Value.absent()
          : Value(urgentMaxRepeats),
      repeatKind: Value(repeatKind),
      daysOfWeekMask: daysOfWeekMask == null && nullToAbsent
          ? const Value.absent()
          : Value(daysOfWeekMask),
      intervalDays: intervalDays == null && nullToAbsent
          ? const Value.absent()
          : Value(intervalDays),
      startDate: Value(startDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      enabled: Value(enabled),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Schedule.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Schedule(
      id: serializer.fromJson<int>(json['id']),
      medicationId: serializer.fromJson<int>(json['medicationId']),
      timeOfDay: serializer.fromJson<String>(json['timeOfDay']),
      remindBeforeMinutes: serializer.fromJson<int?>(
        json['remindBeforeMinutes'],
      ),
      urgentRepeatMinutes: serializer.fromJson<int?>(
        json['urgentRepeatMinutes'],
      ),
      urgentMaxRepeats: serializer.fromJson<int?>(json['urgentMaxRepeats']),
      repeatKind: $SchedulesTable.$converterrepeatKind.fromJson(
        serializer.fromJson<int>(json['repeatKind']),
      ),
      daysOfWeekMask: serializer.fromJson<int?>(json['daysOfWeekMask']),
      intervalDays: serializer.fromJson<int?>(json['intervalDays']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      endDate: serializer.fromJson<DateTime?>(json['endDate']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'medicationId': serializer.toJson<int>(medicationId),
      'timeOfDay': serializer.toJson<String>(timeOfDay),
      'remindBeforeMinutes': serializer.toJson<int?>(remindBeforeMinutes),
      'urgentRepeatMinutes': serializer.toJson<int?>(urgentRepeatMinutes),
      'urgentMaxRepeats': serializer.toJson<int?>(urgentMaxRepeats),
      'repeatKind': serializer.toJson<int>(
        $SchedulesTable.$converterrepeatKind.toJson(repeatKind),
      ),
      'daysOfWeekMask': serializer.toJson<int?>(daysOfWeekMask),
      'intervalDays': serializer.toJson<int?>(intervalDays),
      'startDate': serializer.toJson<DateTime>(startDate),
      'endDate': serializer.toJson<DateTime?>(endDate),
      'enabled': serializer.toJson<bool>(enabled),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Schedule copyWith({
    int? id,
    int? medicationId,
    String? timeOfDay,
    Value<int?> remindBeforeMinutes = const Value.absent(),
    Value<int?> urgentRepeatMinutes = const Value.absent(),
    Value<int?> urgentMaxRepeats = const Value.absent(),
    RepeatKind? repeatKind,
    Value<int?> daysOfWeekMask = const Value.absent(),
    Value<int?> intervalDays = const Value.absent(),
    DateTime? startDate,
    Value<DateTime?> endDate = const Value.absent(),
    bool? enabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Schedule(
    id: id ?? this.id,
    medicationId: medicationId ?? this.medicationId,
    timeOfDay: timeOfDay ?? this.timeOfDay,
    remindBeforeMinutes: remindBeforeMinutes.present
        ? remindBeforeMinutes.value
        : this.remindBeforeMinutes,
    urgentRepeatMinutes: urgentRepeatMinutes.present
        ? urgentRepeatMinutes.value
        : this.urgentRepeatMinutes,
    urgentMaxRepeats: urgentMaxRepeats.present
        ? urgentMaxRepeats.value
        : this.urgentMaxRepeats,
    repeatKind: repeatKind ?? this.repeatKind,
    daysOfWeekMask: daysOfWeekMask.present
        ? daysOfWeekMask.value
        : this.daysOfWeekMask,
    intervalDays: intervalDays.present ? intervalDays.value : this.intervalDays,
    startDate: startDate ?? this.startDate,
    endDate: endDate.present ? endDate.value : this.endDate,
    enabled: enabled ?? this.enabled,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Schedule copyWithCompanion(SchedulesCompanion data) {
    return Schedule(
      id: data.id.present ? data.id.value : this.id,
      medicationId: data.medicationId.present
          ? data.medicationId.value
          : this.medicationId,
      timeOfDay: data.timeOfDay.present ? data.timeOfDay.value : this.timeOfDay,
      remindBeforeMinutes: data.remindBeforeMinutes.present
          ? data.remindBeforeMinutes.value
          : this.remindBeforeMinutes,
      urgentRepeatMinutes: data.urgentRepeatMinutes.present
          ? data.urgentRepeatMinutes.value
          : this.urgentRepeatMinutes,
      urgentMaxRepeats: data.urgentMaxRepeats.present
          ? data.urgentMaxRepeats.value
          : this.urgentMaxRepeats,
      repeatKind: data.repeatKind.present
          ? data.repeatKind.value
          : this.repeatKind,
      daysOfWeekMask: data.daysOfWeekMask.present
          ? data.daysOfWeekMask.value
          : this.daysOfWeekMask,
      intervalDays: data.intervalDays.present
          ? data.intervalDays.value
          : this.intervalDays,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Schedule(')
          ..write('id: $id, ')
          ..write('medicationId: $medicationId, ')
          ..write('timeOfDay: $timeOfDay, ')
          ..write('remindBeforeMinutes: $remindBeforeMinutes, ')
          ..write('urgentRepeatMinutes: $urgentRepeatMinutes, ')
          ..write('urgentMaxRepeats: $urgentMaxRepeats, ')
          ..write('repeatKind: $repeatKind, ')
          ..write('daysOfWeekMask: $daysOfWeekMask, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('enabled: $enabled, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    medicationId,
    timeOfDay,
    remindBeforeMinutes,
    urgentRepeatMinutes,
    urgentMaxRepeats,
    repeatKind,
    daysOfWeekMask,
    intervalDays,
    startDate,
    endDate,
    enabled,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Schedule &&
          other.id == this.id &&
          other.medicationId == this.medicationId &&
          other.timeOfDay == this.timeOfDay &&
          other.remindBeforeMinutes == this.remindBeforeMinutes &&
          other.urgentRepeatMinutes == this.urgentRepeatMinutes &&
          other.urgentMaxRepeats == this.urgentMaxRepeats &&
          other.repeatKind == this.repeatKind &&
          other.daysOfWeekMask == this.daysOfWeekMask &&
          other.intervalDays == this.intervalDays &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.enabled == this.enabled &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SchedulesCompanion extends UpdateCompanion<Schedule> {
  final Value<int> id;
  final Value<int> medicationId;
  final Value<String> timeOfDay;
  final Value<int?> remindBeforeMinutes;
  final Value<int?> urgentRepeatMinutes;
  final Value<int?> urgentMaxRepeats;
  final Value<RepeatKind> repeatKind;
  final Value<int?> daysOfWeekMask;
  final Value<int?> intervalDays;
  final Value<DateTime> startDate;
  final Value<DateTime?> endDate;
  final Value<bool> enabled;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const SchedulesCompanion({
    this.id = const Value.absent(),
    this.medicationId = const Value.absent(),
    this.timeOfDay = const Value.absent(),
    this.remindBeforeMinutes = const Value.absent(),
    this.urgentRepeatMinutes = const Value.absent(),
    this.urgentMaxRepeats = const Value.absent(),
    this.repeatKind = const Value.absent(),
    this.daysOfWeekMask = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.enabled = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SchedulesCompanion.insert({
    this.id = const Value.absent(),
    required int medicationId,
    required String timeOfDay,
    this.remindBeforeMinutes = const Value.absent(),
    this.urgentRepeatMinutes = const Value.absent(),
    this.urgentMaxRepeats = const Value.absent(),
    this.repeatKind = const Value.absent(),
    this.daysOfWeekMask = const Value.absent(),
    this.intervalDays = const Value.absent(),
    required DateTime startDate,
    this.endDate = const Value.absent(),
    this.enabled = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : medicationId = Value(medicationId),
       timeOfDay = Value(timeOfDay),
       startDate = Value(startDate);
  static Insertable<Schedule> custom({
    Expression<int>? id,
    Expression<int>? medicationId,
    Expression<String>? timeOfDay,
    Expression<int>? remindBeforeMinutes,
    Expression<int>? urgentRepeatMinutes,
    Expression<int>? urgentMaxRepeats,
    Expression<int>? repeatKind,
    Expression<int>? daysOfWeekMask,
    Expression<int>? intervalDays,
    Expression<DateTime>? startDate,
    Expression<DateTime>? endDate,
    Expression<bool>? enabled,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (medicationId != null) 'medication_id': medicationId,
      if (timeOfDay != null) 'time_of_day': timeOfDay,
      if (remindBeforeMinutes != null)
        'remind_before_minutes': remindBeforeMinutes,
      if (urgentRepeatMinutes != null)
        'urgent_repeat_minutes': urgentRepeatMinutes,
      if (urgentMaxRepeats != null) 'urgent_max_repeats': urgentMaxRepeats,
      if (repeatKind != null) 'repeat_kind': repeatKind,
      if (daysOfWeekMask != null) 'days_of_week_mask': daysOfWeekMask,
      if (intervalDays != null) 'interval_days': intervalDays,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (enabled != null) 'enabled': enabled,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SchedulesCompanion copyWith({
    Value<int>? id,
    Value<int>? medicationId,
    Value<String>? timeOfDay,
    Value<int?>? remindBeforeMinutes,
    Value<int?>? urgentRepeatMinutes,
    Value<int?>? urgentMaxRepeats,
    Value<RepeatKind>? repeatKind,
    Value<int?>? daysOfWeekMask,
    Value<int?>? intervalDays,
    Value<DateTime>? startDate,
    Value<DateTime?>? endDate,
    Value<bool>? enabled,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return SchedulesCompanion(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      remindBeforeMinutes: remindBeforeMinutes ?? this.remindBeforeMinutes,
      urgentRepeatMinutes: urgentRepeatMinutes ?? this.urgentRepeatMinutes,
      urgentMaxRepeats: urgentMaxRepeats ?? this.urgentMaxRepeats,
      repeatKind: repeatKind ?? this.repeatKind,
      daysOfWeekMask: daysOfWeekMask ?? this.daysOfWeekMask,
      intervalDays: intervalDays ?? this.intervalDays,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (medicationId.present) {
      map['medication_id'] = Variable<int>(medicationId.value);
    }
    if (timeOfDay.present) {
      map['time_of_day'] = Variable<String>(timeOfDay.value);
    }
    if (remindBeforeMinutes.present) {
      map['remind_before_minutes'] = Variable<int>(remindBeforeMinutes.value);
    }
    if (urgentRepeatMinutes.present) {
      map['urgent_repeat_minutes'] = Variable<int>(urgentRepeatMinutes.value);
    }
    if (urgentMaxRepeats.present) {
      map['urgent_max_repeats'] = Variable<int>(urgentMaxRepeats.value);
    }
    if (repeatKind.present) {
      map['repeat_kind'] = Variable<int>(
        $SchedulesTable.$converterrepeatKind.toSql(repeatKind.value),
      );
    }
    if (daysOfWeekMask.present) {
      map['days_of_week_mask'] = Variable<int>(daysOfWeekMask.value);
    }
    if (intervalDays.present) {
      map['interval_days'] = Variable<int>(intervalDays.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SchedulesCompanion(')
          ..write('id: $id, ')
          ..write('medicationId: $medicationId, ')
          ..write('timeOfDay: $timeOfDay, ')
          ..write('remindBeforeMinutes: $remindBeforeMinutes, ')
          ..write('urgentRepeatMinutes: $urgentRepeatMinutes, ')
          ..write('urgentMaxRepeats: $urgentMaxRepeats, ')
          ..write('repeatKind: $repeatKind, ')
          ..write('daysOfWeekMask: $daysOfWeekMask, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('enabled: $enabled, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $IntakeLogsTable extends IntakeLogs
    with TableInfo<$IntakeLogsTable, IntakeLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IntakeLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _medicationIdMeta = const VerificationMeta(
    'medicationId',
  );
  @override
  late final GeneratedColumn<int> medicationId = GeneratedColumn<int>(
    'medication_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES medications (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _scheduleIdMeta = const VerificationMeta(
    'scheduleId',
  );
  @override
  late final GeneratedColumn<int> scheduleId = GeneratedColumn<int>(
    'schedule_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES schedules (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _scheduledAtMeta = const VerificationMeta(
    'scheduledAt',
  );
  @override
  late final GeneratedColumn<DateTime> scheduledAt = GeneratedColumn<DateTime>(
    'scheduled_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actedAtMeta = const VerificationMeta(
    'actedAt',
  );
  @override
  late final GeneratedColumn<DateTime> actedAt = GeneratedColumn<DateTime>(
    'acted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<IntakeStatus, int> status =
      GeneratedColumn<int>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: Constant(IntakeStatus.pending.index),
      ).withConverter<IntakeStatus>($IntakeLogsTable.$converterstatus);
  static const VerificationMeta _urgentFiredCountMeta = const VerificationMeta(
    'urgentFiredCount',
  );
  @override
  late final GeneratedColumn<int> urgentFiredCount = GeneratedColumn<int>(
    'urgent_fired_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _memoMeta = const VerificationMeta('memo');
  @override
  late final GeneratedColumn<String> memo = GeneratedColumn<String>(
    'memo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    medicationId,
    scheduleId,
    scheduledAt,
    actedAt,
    status,
    urgentFiredCount,
    memo,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'intake_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<IntakeLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('medication_id')) {
      context.handle(
        _medicationIdMeta,
        medicationId.isAcceptableOrUnknown(
          data['medication_id']!,
          _medicationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_medicationIdMeta);
    }
    if (data.containsKey('schedule_id')) {
      context.handle(
        _scheduleIdMeta,
        scheduleId.isAcceptableOrUnknown(data['schedule_id']!, _scheduleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_scheduleIdMeta);
    }
    if (data.containsKey('scheduled_at')) {
      context.handle(
        _scheduledAtMeta,
        scheduledAt.isAcceptableOrUnknown(
          data['scheduled_at']!,
          _scheduledAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduledAtMeta);
    }
    if (data.containsKey('acted_at')) {
      context.handle(
        _actedAtMeta,
        actedAt.isAcceptableOrUnknown(data['acted_at']!, _actedAtMeta),
      );
    }
    if (data.containsKey('urgent_fired_count')) {
      context.handle(
        _urgentFiredCountMeta,
        urgentFiredCount.isAcceptableOrUnknown(
          data['urgent_fired_count']!,
          _urgentFiredCountMeta,
        ),
      );
    }
    if (data.containsKey('memo')) {
      context.handle(
        _memoMeta,
        memo.isAcceptableOrUnknown(data['memo']!, _memoMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  IntakeLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IntakeLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      medicationId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}medication_id'],
      )!,
      scheduleId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}schedule_id'],
      )!,
      scheduledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scheduled_at'],
      )!,
      actedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}acted_at'],
      ),
      status: $IntakeLogsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}status'],
        )!,
      ),
      urgentFiredCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}urgent_fired_count'],
      )!,
      memo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}memo'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $IntakeLogsTable createAlias(String alias) {
    return $IntakeLogsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<IntakeStatus, int, int> $converterstatus =
      const EnumIndexConverter<IntakeStatus>(IntakeStatus.values);
}

class IntakeLog extends DataClass implements Insertable<IntakeLog> {
  final int id;
  final int medicationId;
  final int scheduleId;

  /// 예정된 시각 (로컬 wallclock 기준 DateTime)
  final DateTime scheduledAt;

  /// 실제 복용 완료/건너뜀 처리 시각
  final DateTime? actedAt;
  final IntakeStatus status;

  /// 긴급 알람이 몇 번 울렸는지
  final int urgentFiredCount;
  final String? memo;
  final DateTime createdAt;
  final DateTime updatedAt;
  const IntakeLog({
    required this.id,
    required this.medicationId,
    required this.scheduleId,
    required this.scheduledAt,
    this.actedAt,
    required this.status,
    required this.urgentFiredCount,
    this.memo,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['medication_id'] = Variable<int>(medicationId);
    map['schedule_id'] = Variable<int>(scheduleId);
    map['scheduled_at'] = Variable<DateTime>(scheduledAt);
    if (!nullToAbsent || actedAt != null) {
      map['acted_at'] = Variable<DateTime>(actedAt);
    }
    {
      map['status'] = Variable<int>(
        $IntakeLogsTable.$converterstatus.toSql(status),
      );
    }
    map['urgent_fired_count'] = Variable<int>(urgentFiredCount);
    if (!nullToAbsent || memo != null) {
      map['memo'] = Variable<String>(memo);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  IntakeLogsCompanion toCompanion(bool nullToAbsent) {
    return IntakeLogsCompanion(
      id: Value(id),
      medicationId: Value(medicationId),
      scheduleId: Value(scheduleId),
      scheduledAt: Value(scheduledAt),
      actedAt: actedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(actedAt),
      status: Value(status),
      urgentFiredCount: Value(urgentFiredCount),
      memo: memo == null && nullToAbsent ? const Value.absent() : Value(memo),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory IntakeLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IntakeLog(
      id: serializer.fromJson<int>(json['id']),
      medicationId: serializer.fromJson<int>(json['medicationId']),
      scheduleId: serializer.fromJson<int>(json['scheduleId']),
      scheduledAt: serializer.fromJson<DateTime>(json['scheduledAt']),
      actedAt: serializer.fromJson<DateTime?>(json['actedAt']),
      status: $IntakeLogsTable.$converterstatus.fromJson(
        serializer.fromJson<int>(json['status']),
      ),
      urgentFiredCount: serializer.fromJson<int>(json['urgentFiredCount']),
      memo: serializer.fromJson<String?>(json['memo']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'medicationId': serializer.toJson<int>(medicationId),
      'scheduleId': serializer.toJson<int>(scheduleId),
      'scheduledAt': serializer.toJson<DateTime>(scheduledAt),
      'actedAt': serializer.toJson<DateTime?>(actedAt),
      'status': serializer.toJson<int>(
        $IntakeLogsTable.$converterstatus.toJson(status),
      ),
      'urgentFiredCount': serializer.toJson<int>(urgentFiredCount),
      'memo': serializer.toJson<String?>(memo),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  IntakeLog copyWith({
    int? id,
    int? medicationId,
    int? scheduleId,
    DateTime? scheduledAt,
    Value<DateTime?> actedAt = const Value.absent(),
    IntakeStatus? status,
    int? urgentFiredCount,
    Value<String?> memo = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => IntakeLog(
    id: id ?? this.id,
    medicationId: medicationId ?? this.medicationId,
    scheduleId: scheduleId ?? this.scheduleId,
    scheduledAt: scheduledAt ?? this.scheduledAt,
    actedAt: actedAt.present ? actedAt.value : this.actedAt,
    status: status ?? this.status,
    urgentFiredCount: urgentFiredCount ?? this.urgentFiredCount,
    memo: memo.present ? memo.value : this.memo,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  IntakeLog copyWithCompanion(IntakeLogsCompanion data) {
    return IntakeLog(
      id: data.id.present ? data.id.value : this.id,
      medicationId: data.medicationId.present
          ? data.medicationId.value
          : this.medicationId,
      scheduleId: data.scheduleId.present
          ? data.scheduleId.value
          : this.scheduleId,
      scheduledAt: data.scheduledAt.present
          ? data.scheduledAt.value
          : this.scheduledAt,
      actedAt: data.actedAt.present ? data.actedAt.value : this.actedAt,
      status: data.status.present ? data.status.value : this.status,
      urgentFiredCount: data.urgentFiredCount.present
          ? data.urgentFiredCount.value
          : this.urgentFiredCount,
      memo: data.memo.present ? data.memo.value : this.memo,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IntakeLog(')
          ..write('id: $id, ')
          ..write('medicationId: $medicationId, ')
          ..write('scheduleId: $scheduleId, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('actedAt: $actedAt, ')
          ..write('status: $status, ')
          ..write('urgentFiredCount: $urgentFiredCount, ')
          ..write('memo: $memo, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    medicationId,
    scheduleId,
    scheduledAt,
    actedAt,
    status,
    urgentFiredCount,
    memo,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IntakeLog &&
          other.id == this.id &&
          other.medicationId == this.medicationId &&
          other.scheduleId == this.scheduleId &&
          other.scheduledAt == this.scheduledAt &&
          other.actedAt == this.actedAt &&
          other.status == this.status &&
          other.urgentFiredCount == this.urgentFiredCount &&
          other.memo == this.memo &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class IntakeLogsCompanion extends UpdateCompanion<IntakeLog> {
  final Value<int> id;
  final Value<int> medicationId;
  final Value<int> scheduleId;
  final Value<DateTime> scheduledAt;
  final Value<DateTime?> actedAt;
  final Value<IntakeStatus> status;
  final Value<int> urgentFiredCount;
  final Value<String?> memo;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const IntakeLogsCompanion({
    this.id = const Value.absent(),
    this.medicationId = const Value.absent(),
    this.scheduleId = const Value.absent(),
    this.scheduledAt = const Value.absent(),
    this.actedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.urgentFiredCount = const Value.absent(),
    this.memo = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  IntakeLogsCompanion.insert({
    this.id = const Value.absent(),
    required int medicationId,
    required int scheduleId,
    required DateTime scheduledAt,
    this.actedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.urgentFiredCount = const Value.absent(),
    this.memo = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : medicationId = Value(medicationId),
       scheduleId = Value(scheduleId),
       scheduledAt = Value(scheduledAt);
  static Insertable<IntakeLog> custom({
    Expression<int>? id,
    Expression<int>? medicationId,
    Expression<int>? scheduleId,
    Expression<DateTime>? scheduledAt,
    Expression<DateTime>? actedAt,
    Expression<int>? status,
    Expression<int>? urgentFiredCount,
    Expression<String>? memo,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (medicationId != null) 'medication_id': medicationId,
      if (scheduleId != null) 'schedule_id': scheduleId,
      if (scheduledAt != null) 'scheduled_at': scheduledAt,
      if (actedAt != null) 'acted_at': actedAt,
      if (status != null) 'status': status,
      if (urgentFiredCount != null) 'urgent_fired_count': urgentFiredCount,
      if (memo != null) 'memo': memo,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  IntakeLogsCompanion copyWith({
    Value<int>? id,
    Value<int>? medicationId,
    Value<int>? scheduleId,
    Value<DateTime>? scheduledAt,
    Value<DateTime?>? actedAt,
    Value<IntakeStatus>? status,
    Value<int>? urgentFiredCount,
    Value<String?>? memo,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return IntakeLogsCompanion(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      scheduleId: scheduleId ?? this.scheduleId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      actedAt: actedAt ?? this.actedAt,
      status: status ?? this.status,
      urgentFiredCount: urgentFiredCount ?? this.urgentFiredCount,
      memo: memo ?? this.memo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (medicationId.present) {
      map['medication_id'] = Variable<int>(medicationId.value);
    }
    if (scheduleId.present) {
      map['schedule_id'] = Variable<int>(scheduleId.value);
    }
    if (scheduledAt.present) {
      map['scheduled_at'] = Variable<DateTime>(scheduledAt.value);
    }
    if (actedAt.present) {
      map['acted_at'] = Variable<DateTime>(actedAt.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(
        $IntakeLogsTable.$converterstatus.toSql(status.value),
      );
    }
    if (urgentFiredCount.present) {
      map['urgent_fired_count'] = Variable<int>(urgentFiredCount.value);
    }
    if (memo.present) {
      map['memo'] = Variable<String>(memo.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IntakeLogsCompanion(')
          ..write('id: $id, ')
          ..write('medicationId: $medicationId, ')
          ..write('scheduleId: $scheduleId, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('actedAt: $actedAt, ')
          ..write('status: $status, ')
          ..write('urgentFiredCount: $urgentFiredCount, ')
          ..write('memo: $memo, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $IntervalOccurrencesTable extends IntervalOccurrences
    with TableInfo<$IntervalOccurrencesTable, IntervalOccurrence> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IntervalOccurrencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _scheduleIdMeta = const VerificationMeta(
    'scheduleId',
  );
  @override
  late final GeneratedColumn<int> scheduleId = GeneratedColumn<int>(
    'schedule_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES schedules (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _scheduledAtMeta = const VerificationMeta(
    'scheduledAt',
  );
  @override
  late final GeneratedColumn<DateTime> scheduledAt = GeneratedColumn<DateTime>(
    'scheduled_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notifiedMeta = const VerificationMeta(
    'notified',
  );
  @override
  late final GeneratedColumn<bool> notified = GeneratedColumn<bool>(
    'notified',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("notified" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    scheduleId,
    scheduledAt,
    notified,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'interval_occurrences';
  @override
  VerificationContext validateIntegrity(
    Insertable<IntervalOccurrence> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('schedule_id')) {
      context.handle(
        _scheduleIdMeta,
        scheduleId.isAcceptableOrUnknown(data['schedule_id']!, _scheduleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_scheduleIdMeta);
    }
    if (data.containsKey('scheduled_at')) {
      context.handle(
        _scheduledAtMeta,
        scheduledAt.isAcceptableOrUnknown(
          data['scheduled_at']!,
          _scheduledAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduledAtMeta);
    }
    if (data.containsKey('notified')) {
      context.handle(
        _notifiedMeta,
        notified.isAcceptableOrUnknown(data['notified']!, _notifiedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  IntervalOccurrence map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IntervalOccurrence(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      scheduleId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}schedule_id'],
      )!,
      scheduledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scheduled_at'],
      )!,
      notified: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}notified'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $IntervalOccurrencesTable createAlias(String alias) {
    return $IntervalOccurrencesTable(attachedDatabase, alias);
  }
}

class IntervalOccurrence extends DataClass
    implements Insertable<IntervalOccurrence> {
  final int id;
  final int scheduleId;
  final DateTime scheduledAt;
  final bool notified;
  final DateTime createdAt;
  const IntervalOccurrence({
    required this.id,
    required this.scheduleId,
    required this.scheduledAt,
    required this.notified,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['schedule_id'] = Variable<int>(scheduleId);
    map['scheduled_at'] = Variable<DateTime>(scheduledAt);
    map['notified'] = Variable<bool>(notified);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  IntervalOccurrencesCompanion toCompanion(bool nullToAbsent) {
    return IntervalOccurrencesCompanion(
      id: Value(id),
      scheduleId: Value(scheduleId),
      scheduledAt: Value(scheduledAt),
      notified: Value(notified),
      createdAt: Value(createdAt),
    );
  }

  factory IntervalOccurrence.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IntervalOccurrence(
      id: serializer.fromJson<int>(json['id']),
      scheduleId: serializer.fromJson<int>(json['scheduleId']),
      scheduledAt: serializer.fromJson<DateTime>(json['scheduledAt']),
      notified: serializer.fromJson<bool>(json['notified']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'scheduleId': serializer.toJson<int>(scheduleId),
      'scheduledAt': serializer.toJson<DateTime>(scheduledAt),
      'notified': serializer.toJson<bool>(notified),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  IntervalOccurrence copyWith({
    int? id,
    int? scheduleId,
    DateTime? scheduledAt,
    bool? notified,
    DateTime? createdAt,
  }) => IntervalOccurrence(
    id: id ?? this.id,
    scheduleId: scheduleId ?? this.scheduleId,
    scheduledAt: scheduledAt ?? this.scheduledAt,
    notified: notified ?? this.notified,
    createdAt: createdAt ?? this.createdAt,
  );
  IntervalOccurrence copyWithCompanion(IntervalOccurrencesCompanion data) {
    return IntervalOccurrence(
      id: data.id.present ? data.id.value : this.id,
      scheduleId: data.scheduleId.present
          ? data.scheduleId.value
          : this.scheduleId,
      scheduledAt: data.scheduledAt.present
          ? data.scheduledAt.value
          : this.scheduledAt,
      notified: data.notified.present ? data.notified.value : this.notified,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IntervalOccurrence(')
          ..write('id: $id, ')
          ..write('scheduleId: $scheduleId, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('notified: $notified, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, scheduleId, scheduledAt, notified, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IntervalOccurrence &&
          other.id == this.id &&
          other.scheduleId == this.scheduleId &&
          other.scheduledAt == this.scheduledAt &&
          other.notified == this.notified &&
          other.createdAt == this.createdAt);
}

class IntervalOccurrencesCompanion extends UpdateCompanion<IntervalOccurrence> {
  final Value<int> id;
  final Value<int> scheduleId;
  final Value<DateTime> scheduledAt;
  final Value<bool> notified;
  final Value<DateTime> createdAt;
  const IntervalOccurrencesCompanion({
    this.id = const Value.absent(),
    this.scheduleId = const Value.absent(),
    this.scheduledAt = const Value.absent(),
    this.notified = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  IntervalOccurrencesCompanion.insert({
    this.id = const Value.absent(),
    required int scheduleId,
    required DateTime scheduledAt,
    this.notified = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : scheduleId = Value(scheduleId),
       scheduledAt = Value(scheduledAt);
  static Insertable<IntervalOccurrence> custom({
    Expression<int>? id,
    Expression<int>? scheduleId,
    Expression<DateTime>? scheduledAt,
    Expression<bool>? notified,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (scheduleId != null) 'schedule_id': scheduleId,
      if (scheduledAt != null) 'scheduled_at': scheduledAt,
      if (notified != null) 'notified': notified,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  IntervalOccurrencesCompanion copyWith({
    Value<int>? id,
    Value<int>? scheduleId,
    Value<DateTime>? scheduledAt,
    Value<bool>? notified,
    Value<DateTime>? createdAt,
  }) {
    return IntervalOccurrencesCompanion(
      id: id ?? this.id,
      scheduleId: scheduleId ?? this.scheduleId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      notified: notified ?? this.notified,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (scheduleId.present) {
      map['schedule_id'] = Variable<int>(scheduleId.value);
    }
    if (scheduledAt.present) {
      map['scheduled_at'] = Variable<DateTime>(scheduledAt.value);
    }
    if (notified.present) {
      map['notified'] = Variable<bool>(notified.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IntervalOccurrencesCompanion(')
          ..write('id: $id, ')
          ..write('scheduleId: $scheduleId, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('notified: $notified, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MedicationsTable medications = $MedicationsTable(this);
  late final $SchedulesTable schedules = $SchedulesTable(this);
  late final $IntakeLogsTable intakeLogs = $IntakeLogsTable(this);
  late final $IntervalOccurrencesTable intervalOccurrences =
      $IntervalOccurrencesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    medications,
    schedules,
    intakeLogs,
    intervalOccurrences,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'medications',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('schedules', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'medications',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('intake_logs', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'schedules',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('intake_logs', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'schedules',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('interval_occurrences', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$MedicationsTableCreateCompanionBuilder =
    MedicationsCompanion Function({
      Value<int> id,
      required String name,
      Value<String?> category,
      Value<String?> dosage,
      Value<String?> unit,
      Value<String?> shape,
      Value<String?> colorHex,
      Value<String?> memo,
      Value<String?> iconKey,
      Value<bool> archived,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$MedicationsTableUpdateCompanionBuilder =
    MedicationsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String?> category,
      Value<String?> dosage,
      Value<String?> unit,
      Value<String?> shape,
      Value<String?> colorHex,
      Value<String?> memo,
      Value<String?> iconKey,
      Value<bool> archived,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$MedicationsTableReferences
    extends BaseReferences<_$AppDatabase, $MedicationsTable, Medication> {
  $$MedicationsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SchedulesTable, List<Schedule>>
  _schedulesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.schedules,
    aliasName: $_aliasNameGenerator(
      db.medications.id,
      db.schedules.medicationId,
    ),
  );

  $$SchedulesTableProcessedTableManager get schedulesRefs {
    final manager = $$SchedulesTableTableManager(
      $_db,
      $_db.schedules,
    ).filter((f) => f.medicationId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_schedulesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$IntakeLogsTable, List<IntakeLog>>
  _intakeLogsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.intakeLogs,
    aliasName: $_aliasNameGenerator(
      db.medications.id,
      db.intakeLogs.medicationId,
    ),
  );

  $$IntakeLogsTableProcessedTableManager get intakeLogsRefs {
    final manager = $$IntakeLogsTableTableManager(
      $_db,
      $_db.intakeLogs,
    ).filter((f) => f.medicationId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_intakeLogsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MedicationsTableFilterComposer
    extends Composer<_$AppDatabase, $MedicationsTable> {
  $$MedicationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dosage => $composableBuilder(
    column: $table.dosage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shape => $composableBuilder(
    column: $table.shape,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconKey => $composableBuilder(
    column: $table.iconKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> schedulesRefs(
    Expression<bool> Function($$SchedulesTableFilterComposer f) f,
  ) {
    final $$SchedulesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.schedules,
      getReferencedColumn: (t) => t.medicationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SchedulesTableFilterComposer(
            $db: $db,
            $table: $db.schedules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> intakeLogsRefs(
    Expression<bool> Function($$IntakeLogsTableFilterComposer f) f,
  ) {
    final $$IntakeLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.intakeLogs,
      getReferencedColumn: (t) => t.medicationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IntakeLogsTableFilterComposer(
            $db: $db,
            $table: $db.intakeLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MedicationsTableOrderingComposer
    extends Composer<_$AppDatabase, $MedicationsTable> {
  $$MedicationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dosage => $composableBuilder(
    column: $table.dosage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shape => $composableBuilder(
    column: $table.shape,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconKey => $composableBuilder(
    column: $table.iconKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MedicationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MedicationsTable> {
  $$MedicationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get dosage =>
      $composableBuilder(column: $table.dosage, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get shape =>
      $composableBuilder(column: $table.shape, builder: (column) => column);

  GeneratedColumn<String> get colorHex =>
      $composableBuilder(column: $table.colorHex, builder: (column) => column);

  GeneratedColumn<String> get memo =>
      $composableBuilder(column: $table.memo, builder: (column) => column);

  GeneratedColumn<String> get iconKey =>
      $composableBuilder(column: $table.iconKey, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> schedulesRefs<T extends Object>(
    Expression<T> Function($$SchedulesTableAnnotationComposer a) f,
  ) {
    final $$SchedulesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.schedules,
      getReferencedColumn: (t) => t.medicationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SchedulesTableAnnotationComposer(
            $db: $db,
            $table: $db.schedules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> intakeLogsRefs<T extends Object>(
    Expression<T> Function($$IntakeLogsTableAnnotationComposer a) f,
  ) {
    final $$IntakeLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.intakeLogs,
      getReferencedColumn: (t) => t.medicationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IntakeLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.intakeLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MedicationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MedicationsTable,
          Medication,
          $$MedicationsTableFilterComposer,
          $$MedicationsTableOrderingComposer,
          $$MedicationsTableAnnotationComposer,
          $$MedicationsTableCreateCompanionBuilder,
          $$MedicationsTableUpdateCompanionBuilder,
          (Medication, $$MedicationsTableReferences),
          Medication,
          PrefetchHooks Function({bool schedulesRefs, bool intakeLogsRefs})
        > {
  $$MedicationsTableTableManager(_$AppDatabase db, $MedicationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MedicationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MedicationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MedicationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String?> dosage = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<String?> shape = const Value.absent(),
                Value<String?> colorHex = const Value.absent(),
                Value<String?> memo = const Value.absent(),
                Value<String?> iconKey = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => MedicationsCompanion(
                id: id,
                name: name,
                category: category,
                dosage: dosage,
                unit: unit,
                shape: shape,
                colorHex: colorHex,
                memo: memo,
                iconKey: iconKey,
                archived: archived,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> category = const Value.absent(),
                Value<String?> dosage = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<String?> shape = const Value.absent(),
                Value<String?> colorHex = const Value.absent(),
                Value<String?> memo = const Value.absent(),
                Value<String?> iconKey = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => MedicationsCompanion.insert(
                id: id,
                name: name,
                category: category,
                dosage: dosage,
                unit: unit,
                shape: shape,
                colorHex: colorHex,
                memo: memo,
                iconKey: iconKey,
                archived: archived,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MedicationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({schedulesRefs = false, intakeLogsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (schedulesRefs) db.schedules,
                    if (intakeLogsRefs) db.intakeLogs,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (schedulesRefs)
                        await $_getPrefetchedData<
                          Medication,
                          $MedicationsTable,
                          Schedule
                        >(
                          currentTable: table,
                          referencedTable: $$MedicationsTableReferences
                              ._schedulesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MedicationsTableReferences(
                                db,
                                table,
                                p0,
                              ).schedulesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.medicationId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (intakeLogsRefs)
                        await $_getPrefetchedData<
                          Medication,
                          $MedicationsTable,
                          IntakeLog
                        >(
                          currentTable: table,
                          referencedTable: $$MedicationsTableReferences
                              ._intakeLogsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MedicationsTableReferences(
                                db,
                                table,
                                p0,
                              ).intakeLogsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.medicationId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$MedicationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MedicationsTable,
      Medication,
      $$MedicationsTableFilterComposer,
      $$MedicationsTableOrderingComposer,
      $$MedicationsTableAnnotationComposer,
      $$MedicationsTableCreateCompanionBuilder,
      $$MedicationsTableUpdateCompanionBuilder,
      (Medication, $$MedicationsTableReferences),
      Medication,
      PrefetchHooks Function({bool schedulesRefs, bool intakeLogsRefs})
    >;
typedef $$SchedulesTableCreateCompanionBuilder =
    SchedulesCompanion Function({
      Value<int> id,
      required int medicationId,
      required String timeOfDay,
      Value<int?> remindBeforeMinutes,
      Value<int?> urgentRepeatMinutes,
      Value<int?> urgentMaxRepeats,
      Value<RepeatKind> repeatKind,
      Value<int?> daysOfWeekMask,
      Value<int?> intervalDays,
      required DateTime startDate,
      Value<DateTime?> endDate,
      Value<bool> enabled,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$SchedulesTableUpdateCompanionBuilder =
    SchedulesCompanion Function({
      Value<int> id,
      Value<int> medicationId,
      Value<String> timeOfDay,
      Value<int?> remindBeforeMinutes,
      Value<int?> urgentRepeatMinutes,
      Value<int?> urgentMaxRepeats,
      Value<RepeatKind> repeatKind,
      Value<int?> daysOfWeekMask,
      Value<int?> intervalDays,
      Value<DateTime> startDate,
      Value<DateTime?> endDate,
      Value<bool> enabled,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$SchedulesTableReferences
    extends BaseReferences<_$AppDatabase, $SchedulesTable, Schedule> {
  $$SchedulesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MedicationsTable _medicationIdTable(_$AppDatabase db) =>
      db.medications.createAlias(
        $_aliasNameGenerator(db.schedules.medicationId, db.medications.id),
      );

  $$MedicationsTableProcessedTableManager get medicationId {
    final $_column = $_itemColumn<int>('medication_id')!;

    final manager = $$MedicationsTableTableManager(
      $_db,
      $_db.medications,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_medicationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$IntakeLogsTable, List<IntakeLog>>
  _intakeLogsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.intakeLogs,
    aliasName: $_aliasNameGenerator(db.schedules.id, db.intakeLogs.scheduleId),
  );

  $$IntakeLogsTableProcessedTableManager get intakeLogsRefs {
    final manager = $$IntakeLogsTableTableManager(
      $_db,
      $_db.intakeLogs,
    ).filter((f) => f.scheduleId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_intakeLogsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $IntervalOccurrencesTable,
    List<IntervalOccurrence>
  >
  _intervalOccurrencesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.intervalOccurrences,
        aliasName: $_aliasNameGenerator(
          db.schedules.id,
          db.intervalOccurrences.scheduleId,
        ),
      );

  $$IntervalOccurrencesTableProcessedTableManager get intervalOccurrencesRefs {
    final manager = $$IntervalOccurrencesTableTableManager(
      $_db,
      $_db.intervalOccurrences,
    ).filter((f) => f.scheduleId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _intervalOccurrencesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SchedulesTableFilterComposer
    extends Composer<_$AppDatabase, $SchedulesTable> {
  $$SchedulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timeOfDay => $composableBuilder(
    column: $table.timeOfDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get remindBeforeMinutes => $composableBuilder(
    column: $table.remindBeforeMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get urgentRepeatMinutes => $composableBuilder(
    column: $table.urgentRepeatMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get urgentMaxRepeats => $composableBuilder(
    column: $table.urgentMaxRepeats,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<RepeatKind, RepeatKind, int> get repeatKind =>
      $composableBuilder(
        column: $table.repeatKind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get daysOfWeekMask => $composableBuilder(
    column: $table.daysOfWeekMask,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$MedicationsTableFilterComposer get medicationId {
    final $$MedicationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.medicationId,
      referencedTable: $db.medications,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MedicationsTableFilterComposer(
            $db: $db,
            $table: $db.medications,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> intakeLogsRefs(
    Expression<bool> Function($$IntakeLogsTableFilterComposer f) f,
  ) {
    final $$IntakeLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.intakeLogs,
      getReferencedColumn: (t) => t.scheduleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IntakeLogsTableFilterComposer(
            $db: $db,
            $table: $db.intakeLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> intervalOccurrencesRefs(
    Expression<bool> Function($$IntervalOccurrencesTableFilterComposer f) f,
  ) {
    final $$IntervalOccurrencesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.intervalOccurrences,
      getReferencedColumn: (t) => t.scheduleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IntervalOccurrencesTableFilterComposer(
            $db: $db,
            $table: $db.intervalOccurrences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SchedulesTableOrderingComposer
    extends Composer<_$AppDatabase, $SchedulesTable> {
  $$SchedulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timeOfDay => $composableBuilder(
    column: $table.timeOfDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get remindBeforeMinutes => $composableBuilder(
    column: $table.remindBeforeMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get urgentRepeatMinutes => $composableBuilder(
    column: $table.urgentRepeatMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get urgentMaxRepeats => $composableBuilder(
    column: $table.urgentMaxRepeats,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get repeatKind => $composableBuilder(
    column: $table.repeatKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get daysOfWeekMask => $composableBuilder(
    column: $table.daysOfWeekMask,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$MedicationsTableOrderingComposer get medicationId {
    final $$MedicationsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.medicationId,
      referencedTable: $db.medications,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MedicationsTableOrderingComposer(
            $db: $db,
            $table: $db.medications,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SchedulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SchedulesTable> {
  $$SchedulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get timeOfDay =>
      $composableBuilder(column: $table.timeOfDay, builder: (column) => column);

  GeneratedColumn<int> get remindBeforeMinutes => $composableBuilder(
    column: $table.remindBeforeMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get urgentRepeatMinutes => $composableBuilder(
    column: $table.urgentRepeatMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get urgentMaxRepeats => $composableBuilder(
    column: $table.urgentMaxRepeats,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<RepeatKind, int> get repeatKind =>
      $composableBuilder(
        column: $table.repeatKind,
        builder: (column) => column,
      );

  GeneratedColumn<int> get daysOfWeekMask => $composableBuilder(
    column: $table.daysOfWeekMask,
    builder: (column) => column,
  );

  GeneratedColumn<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$MedicationsTableAnnotationComposer get medicationId {
    final $$MedicationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.medicationId,
      referencedTable: $db.medications,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MedicationsTableAnnotationComposer(
            $db: $db,
            $table: $db.medications,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> intakeLogsRefs<T extends Object>(
    Expression<T> Function($$IntakeLogsTableAnnotationComposer a) f,
  ) {
    final $$IntakeLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.intakeLogs,
      getReferencedColumn: (t) => t.scheduleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IntakeLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.intakeLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> intervalOccurrencesRefs<T extends Object>(
    Expression<T> Function($$IntervalOccurrencesTableAnnotationComposer a) f,
  ) {
    final $$IntervalOccurrencesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.intervalOccurrences,
          getReferencedColumn: (t) => t.scheduleId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$IntervalOccurrencesTableAnnotationComposer(
                $db: $db,
                $table: $db.intervalOccurrences,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$SchedulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SchedulesTable,
          Schedule,
          $$SchedulesTableFilterComposer,
          $$SchedulesTableOrderingComposer,
          $$SchedulesTableAnnotationComposer,
          $$SchedulesTableCreateCompanionBuilder,
          $$SchedulesTableUpdateCompanionBuilder,
          (Schedule, $$SchedulesTableReferences),
          Schedule,
          PrefetchHooks Function({
            bool medicationId,
            bool intakeLogsRefs,
            bool intervalOccurrencesRefs,
          })
        > {
  $$SchedulesTableTableManager(_$AppDatabase db, $SchedulesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SchedulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SchedulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SchedulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> medicationId = const Value.absent(),
                Value<String> timeOfDay = const Value.absent(),
                Value<int?> remindBeforeMinutes = const Value.absent(),
                Value<int?> urgentRepeatMinutes = const Value.absent(),
                Value<int?> urgentMaxRepeats = const Value.absent(),
                Value<RepeatKind> repeatKind = const Value.absent(),
                Value<int?> daysOfWeekMask = const Value.absent(),
                Value<int?> intervalDays = const Value.absent(),
                Value<DateTime> startDate = const Value.absent(),
                Value<DateTime?> endDate = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SchedulesCompanion(
                id: id,
                medicationId: medicationId,
                timeOfDay: timeOfDay,
                remindBeforeMinutes: remindBeforeMinutes,
                urgentRepeatMinutes: urgentRepeatMinutes,
                urgentMaxRepeats: urgentMaxRepeats,
                repeatKind: repeatKind,
                daysOfWeekMask: daysOfWeekMask,
                intervalDays: intervalDays,
                startDate: startDate,
                endDate: endDate,
                enabled: enabled,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int medicationId,
                required String timeOfDay,
                Value<int?> remindBeforeMinutes = const Value.absent(),
                Value<int?> urgentRepeatMinutes = const Value.absent(),
                Value<int?> urgentMaxRepeats = const Value.absent(),
                Value<RepeatKind> repeatKind = const Value.absent(),
                Value<int?> daysOfWeekMask = const Value.absent(),
                Value<int?> intervalDays = const Value.absent(),
                required DateTime startDate,
                Value<DateTime?> endDate = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SchedulesCompanion.insert(
                id: id,
                medicationId: medicationId,
                timeOfDay: timeOfDay,
                remindBeforeMinutes: remindBeforeMinutes,
                urgentRepeatMinutes: urgentRepeatMinutes,
                urgentMaxRepeats: urgentMaxRepeats,
                repeatKind: repeatKind,
                daysOfWeekMask: daysOfWeekMask,
                intervalDays: intervalDays,
                startDate: startDate,
                endDate: endDate,
                enabled: enabled,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SchedulesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                medicationId = false,
                intakeLogsRefs = false,
                intervalOccurrencesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (intakeLogsRefs) db.intakeLogs,
                    if (intervalOccurrencesRefs) db.intervalOccurrences,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (medicationId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.medicationId,
                                    referencedTable: $$SchedulesTableReferences
                                        ._medicationIdTable(db),
                                    referencedColumn: $$SchedulesTableReferences
                                        ._medicationIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (intakeLogsRefs)
                        await $_getPrefetchedData<
                          Schedule,
                          $SchedulesTable,
                          IntakeLog
                        >(
                          currentTable: table,
                          referencedTable: $$SchedulesTableReferences
                              ._intakeLogsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SchedulesTableReferences(
                                db,
                                table,
                                p0,
                              ).intakeLogsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.scheduleId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (intervalOccurrencesRefs)
                        await $_getPrefetchedData<
                          Schedule,
                          $SchedulesTable,
                          IntervalOccurrence
                        >(
                          currentTable: table,
                          referencedTable: $$SchedulesTableReferences
                              ._intervalOccurrencesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SchedulesTableReferences(
                                db,
                                table,
                                p0,
                              ).intervalOccurrencesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.scheduleId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$SchedulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SchedulesTable,
      Schedule,
      $$SchedulesTableFilterComposer,
      $$SchedulesTableOrderingComposer,
      $$SchedulesTableAnnotationComposer,
      $$SchedulesTableCreateCompanionBuilder,
      $$SchedulesTableUpdateCompanionBuilder,
      (Schedule, $$SchedulesTableReferences),
      Schedule,
      PrefetchHooks Function({
        bool medicationId,
        bool intakeLogsRefs,
        bool intervalOccurrencesRefs,
      })
    >;
typedef $$IntakeLogsTableCreateCompanionBuilder =
    IntakeLogsCompanion Function({
      Value<int> id,
      required int medicationId,
      required int scheduleId,
      required DateTime scheduledAt,
      Value<DateTime?> actedAt,
      Value<IntakeStatus> status,
      Value<int> urgentFiredCount,
      Value<String?> memo,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$IntakeLogsTableUpdateCompanionBuilder =
    IntakeLogsCompanion Function({
      Value<int> id,
      Value<int> medicationId,
      Value<int> scheduleId,
      Value<DateTime> scheduledAt,
      Value<DateTime?> actedAt,
      Value<IntakeStatus> status,
      Value<int> urgentFiredCount,
      Value<String?> memo,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$IntakeLogsTableReferences
    extends BaseReferences<_$AppDatabase, $IntakeLogsTable, IntakeLog> {
  $$IntakeLogsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MedicationsTable _medicationIdTable(_$AppDatabase db) =>
      db.medications.createAlias(
        $_aliasNameGenerator(db.intakeLogs.medicationId, db.medications.id),
      );

  $$MedicationsTableProcessedTableManager get medicationId {
    final $_column = $_itemColumn<int>('medication_id')!;

    final manager = $$MedicationsTableTableManager(
      $_db,
      $_db.medications,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_medicationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $SchedulesTable _scheduleIdTable(_$AppDatabase db) =>
      db.schedules.createAlias(
        $_aliasNameGenerator(db.intakeLogs.scheduleId, db.schedules.id),
      );

  $$SchedulesTableProcessedTableManager get scheduleId {
    final $_column = $_itemColumn<int>('schedule_id')!;

    final manager = $$SchedulesTableTableManager(
      $_db,
      $_db.schedules,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_scheduleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$IntakeLogsTableFilterComposer
    extends Composer<_$AppDatabase, $IntakeLogsTable> {
  $$IntakeLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get actedAt => $composableBuilder(
    column: $table.actedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<IntakeStatus, IntakeStatus, int> get status =>
      $composableBuilder(
        column: $table.status,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get urgentFiredCount => $composableBuilder(
    column: $table.urgentFiredCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$MedicationsTableFilterComposer get medicationId {
    final $$MedicationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.medicationId,
      referencedTable: $db.medications,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MedicationsTableFilterComposer(
            $db: $db,
            $table: $db.medications,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SchedulesTableFilterComposer get scheduleId {
    final $$SchedulesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scheduleId,
      referencedTable: $db.schedules,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SchedulesTableFilterComposer(
            $db: $db,
            $table: $db.schedules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IntakeLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $IntakeLogsTable> {
  $$IntakeLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get actedAt => $composableBuilder(
    column: $table.actedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get urgentFiredCount => $composableBuilder(
    column: $table.urgentFiredCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memo => $composableBuilder(
    column: $table.memo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$MedicationsTableOrderingComposer get medicationId {
    final $$MedicationsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.medicationId,
      referencedTable: $db.medications,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MedicationsTableOrderingComposer(
            $db: $db,
            $table: $db.medications,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SchedulesTableOrderingComposer get scheduleId {
    final $$SchedulesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scheduleId,
      referencedTable: $db.schedules,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SchedulesTableOrderingComposer(
            $db: $db,
            $table: $db.schedules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IntakeLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $IntakeLogsTable> {
  $$IntakeLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get actedAt =>
      $composableBuilder(column: $table.actedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<IntakeStatus, int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get urgentFiredCount => $composableBuilder(
    column: $table.urgentFiredCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get memo =>
      $composableBuilder(column: $table.memo, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$MedicationsTableAnnotationComposer get medicationId {
    final $$MedicationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.medicationId,
      referencedTable: $db.medications,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MedicationsTableAnnotationComposer(
            $db: $db,
            $table: $db.medications,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SchedulesTableAnnotationComposer get scheduleId {
    final $$SchedulesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scheduleId,
      referencedTable: $db.schedules,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SchedulesTableAnnotationComposer(
            $db: $db,
            $table: $db.schedules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IntakeLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IntakeLogsTable,
          IntakeLog,
          $$IntakeLogsTableFilterComposer,
          $$IntakeLogsTableOrderingComposer,
          $$IntakeLogsTableAnnotationComposer,
          $$IntakeLogsTableCreateCompanionBuilder,
          $$IntakeLogsTableUpdateCompanionBuilder,
          (IntakeLog, $$IntakeLogsTableReferences),
          IntakeLog,
          PrefetchHooks Function({bool medicationId, bool scheduleId})
        > {
  $$IntakeLogsTableTableManager(_$AppDatabase db, $IntakeLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IntakeLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IntakeLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IntakeLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> medicationId = const Value.absent(),
                Value<int> scheduleId = const Value.absent(),
                Value<DateTime> scheduledAt = const Value.absent(),
                Value<DateTime?> actedAt = const Value.absent(),
                Value<IntakeStatus> status = const Value.absent(),
                Value<int> urgentFiredCount = const Value.absent(),
                Value<String?> memo = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => IntakeLogsCompanion(
                id: id,
                medicationId: medicationId,
                scheduleId: scheduleId,
                scheduledAt: scheduledAt,
                actedAt: actedAt,
                status: status,
                urgentFiredCount: urgentFiredCount,
                memo: memo,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int medicationId,
                required int scheduleId,
                required DateTime scheduledAt,
                Value<DateTime?> actedAt = const Value.absent(),
                Value<IntakeStatus> status = const Value.absent(),
                Value<int> urgentFiredCount = const Value.absent(),
                Value<String?> memo = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => IntakeLogsCompanion.insert(
                id: id,
                medicationId: medicationId,
                scheduleId: scheduleId,
                scheduledAt: scheduledAt,
                actedAt: actedAt,
                status: status,
                urgentFiredCount: urgentFiredCount,
                memo: memo,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$IntakeLogsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({medicationId = false, scheduleId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (medicationId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.medicationId,
                                referencedTable: $$IntakeLogsTableReferences
                                    ._medicationIdTable(db),
                                referencedColumn: $$IntakeLogsTableReferences
                                    ._medicationIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (scheduleId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.scheduleId,
                                referencedTable: $$IntakeLogsTableReferences
                                    ._scheduleIdTable(db),
                                referencedColumn: $$IntakeLogsTableReferences
                                    ._scheduleIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$IntakeLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IntakeLogsTable,
      IntakeLog,
      $$IntakeLogsTableFilterComposer,
      $$IntakeLogsTableOrderingComposer,
      $$IntakeLogsTableAnnotationComposer,
      $$IntakeLogsTableCreateCompanionBuilder,
      $$IntakeLogsTableUpdateCompanionBuilder,
      (IntakeLog, $$IntakeLogsTableReferences),
      IntakeLog,
      PrefetchHooks Function({bool medicationId, bool scheduleId})
    >;
typedef $$IntervalOccurrencesTableCreateCompanionBuilder =
    IntervalOccurrencesCompanion Function({
      Value<int> id,
      required int scheduleId,
      required DateTime scheduledAt,
      Value<bool> notified,
      Value<DateTime> createdAt,
    });
typedef $$IntervalOccurrencesTableUpdateCompanionBuilder =
    IntervalOccurrencesCompanion Function({
      Value<int> id,
      Value<int> scheduleId,
      Value<DateTime> scheduledAt,
      Value<bool> notified,
      Value<DateTime> createdAt,
    });

final class $$IntervalOccurrencesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $IntervalOccurrencesTable,
          IntervalOccurrence
        > {
  $$IntervalOccurrencesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SchedulesTable _scheduleIdTable(_$AppDatabase db) =>
      db.schedules.createAlias(
        $_aliasNameGenerator(
          db.intervalOccurrences.scheduleId,
          db.schedules.id,
        ),
      );

  $$SchedulesTableProcessedTableManager get scheduleId {
    final $_column = $_itemColumn<int>('schedule_id')!;

    final manager = $$SchedulesTableTableManager(
      $_db,
      $_db.schedules,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_scheduleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$IntervalOccurrencesTableFilterComposer
    extends Composer<_$AppDatabase, $IntervalOccurrencesTable> {
  $$IntervalOccurrencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get notified => $composableBuilder(
    column: $table.notified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$SchedulesTableFilterComposer get scheduleId {
    final $$SchedulesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scheduleId,
      referencedTable: $db.schedules,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SchedulesTableFilterComposer(
            $db: $db,
            $table: $db.schedules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IntervalOccurrencesTableOrderingComposer
    extends Composer<_$AppDatabase, $IntervalOccurrencesTable> {
  $$IntervalOccurrencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get notified => $composableBuilder(
    column: $table.notified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SchedulesTableOrderingComposer get scheduleId {
    final $$SchedulesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scheduleId,
      referencedTable: $db.schedules,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SchedulesTableOrderingComposer(
            $db: $db,
            $table: $db.schedules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IntervalOccurrencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $IntervalOccurrencesTable> {
  $$IntervalOccurrencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get notified =>
      $composableBuilder(column: $table.notified, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$SchedulesTableAnnotationComposer get scheduleId {
    final $$SchedulesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scheduleId,
      referencedTable: $db.schedules,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SchedulesTableAnnotationComposer(
            $db: $db,
            $table: $db.schedules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IntervalOccurrencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IntervalOccurrencesTable,
          IntervalOccurrence,
          $$IntervalOccurrencesTableFilterComposer,
          $$IntervalOccurrencesTableOrderingComposer,
          $$IntervalOccurrencesTableAnnotationComposer,
          $$IntervalOccurrencesTableCreateCompanionBuilder,
          $$IntervalOccurrencesTableUpdateCompanionBuilder,
          (IntervalOccurrence, $$IntervalOccurrencesTableReferences),
          IntervalOccurrence,
          PrefetchHooks Function({bool scheduleId})
        > {
  $$IntervalOccurrencesTableTableManager(
    _$AppDatabase db,
    $IntervalOccurrencesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IntervalOccurrencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IntervalOccurrencesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$IntervalOccurrencesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> scheduleId = const Value.absent(),
                Value<DateTime> scheduledAt = const Value.absent(),
                Value<bool> notified = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => IntervalOccurrencesCompanion(
                id: id,
                scheduleId: scheduleId,
                scheduledAt: scheduledAt,
                notified: notified,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int scheduleId,
                required DateTime scheduledAt,
                Value<bool> notified = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => IntervalOccurrencesCompanion.insert(
                id: id,
                scheduleId: scheduleId,
                scheduledAt: scheduledAt,
                notified: notified,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$IntervalOccurrencesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({scheduleId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (scheduleId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.scheduleId,
                                referencedTable:
                                    $$IntervalOccurrencesTableReferences
                                        ._scheduleIdTable(db),
                                referencedColumn:
                                    $$IntervalOccurrencesTableReferences
                                        ._scheduleIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$IntervalOccurrencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IntervalOccurrencesTable,
      IntervalOccurrence,
      $$IntervalOccurrencesTableFilterComposer,
      $$IntervalOccurrencesTableOrderingComposer,
      $$IntervalOccurrencesTableAnnotationComposer,
      $$IntervalOccurrencesTableCreateCompanionBuilder,
      $$IntervalOccurrencesTableUpdateCompanionBuilder,
      (IntervalOccurrence, $$IntervalOccurrencesTableReferences),
      IntervalOccurrence,
      PrefetchHooks Function({bool scheduleId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MedicationsTableTableManager get medications =>
      $$MedicationsTableTableManager(_db, _db.medications);
  $$SchedulesTableTableManager get schedules =>
      $$SchedulesTableTableManager(_db, _db.schedules);
  $$IntakeLogsTableTableManager get intakeLogs =>
      $$IntakeLogsTableTableManager(_db, _db.intakeLogs);
  $$IntervalOccurrencesTableTableManager get intervalOccurrences =>
      $$IntervalOccurrencesTableTableManager(_db, _db.intervalOccurrences);
}
