// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CategoriesTableTable extends CategoriesTable
    with TableInfo<$CategoriesTableTable, CategoriesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastUsedAtMeta =
      const VerificationMeta('lastUsedAt');
  @override
  late final GeneratedColumn<DateTime> lastUsedAt = GeneratedColumn<DateTime>(
      'last_used_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
      'color', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, userId, name, sortOrder, lastUsedAt, createdAt, color];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<CategoriesTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('last_used_at')) {
      context.handle(
          _lastUsedAtMeta,
          lastUsedAt.isAcceptableOrUnknown(
              data['last_used_at']!, _lastUsedAtMeta));
    } else if (isInserting) {
      context.missing(_lastUsedAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
          _colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoriesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoriesTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      lastUsedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_used_at'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      color: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color']),
    );
  }

  @override
  $CategoriesTableTable createAlias(String alias) {
    return $CategoriesTableTable(attachedDatabase, alias);
  }
}

class CategoriesTableData extends DataClass
    implements Insertable<CategoriesTableData> {
  final String id;
  final String userId;
  final String name;
  final int sortOrder;
  final DateTime lastUsedAt;
  final DateTime createdAt;
  final String? color;
  const CategoriesTableData(
      {required this.id,
      required this.userId,
      required this.name,
      required this.sortOrder,
      required this.lastUsedAt,
      required this.createdAt,
      this.color});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['name'] = Variable<String>(name);
    map['sort_order'] = Variable<int>(sortOrder);
    map['last_used_at'] = Variable<DateTime>(lastUsedAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    return map;
  }

  CategoriesTableCompanion toCompanion(bool nullToAbsent) {
    return CategoriesTableCompanion(
      id: Value(id),
      userId: Value(userId),
      name: Value(name),
      sortOrder: Value(sortOrder),
      lastUsedAt: Value(lastUsedAt),
      createdAt: Value(createdAt),
      color:
          color == null && nullToAbsent ? const Value.absent() : Value(color),
    );
  }

  factory CategoriesTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoriesTableData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      name: serializer.fromJson<String>(json['name']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      lastUsedAt: serializer.fromJson<DateTime>(json['lastUsedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      color: serializer.fromJson<String?>(json['color']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'name': serializer.toJson<String>(name),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'lastUsedAt': serializer.toJson<DateTime>(lastUsedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'color': serializer.toJson<String?>(color),
    };
  }

  CategoriesTableData copyWith(
          {String? id,
          String? userId,
          String? name,
          int? sortOrder,
          DateTime? lastUsedAt,
          DateTime? createdAt,
          Value<String?> color = const Value.absent()}) =>
      CategoriesTableData(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        name: name ?? this.name,
        sortOrder: sortOrder ?? this.sortOrder,
        lastUsedAt: lastUsedAt ?? this.lastUsedAt,
        createdAt: createdAt ?? this.createdAt,
        color: color.present ? color.value : this.color,
      );
  CategoriesTableData copyWithCompanion(CategoriesTableCompanion data) {
    return CategoriesTableData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      name: data.name.present ? data.name.value : this.name,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      lastUsedAt:
          data.lastUsedAt.present ? data.lastUsedAt.value : this.lastUsedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      color: data.color.present ? data.color.value : this.color,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesTableData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('color: $color')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, userId, name, sortOrder, lastUsedAt, createdAt, color);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoriesTableData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.sortOrder == this.sortOrder &&
          other.lastUsedAt == this.lastUsedAt &&
          other.createdAt == this.createdAt &&
          other.color == this.color);
}

class CategoriesTableCompanion extends UpdateCompanion<CategoriesTableData> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> name;
  final Value<int> sortOrder;
  final Value<DateTime> lastUsedAt;
  final Value<DateTime> createdAt;
  final Value<String?> color;
  final Value<int> rowid;
  const CategoriesTableCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.color = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesTableCompanion.insert({
    required String id,
    required String userId,
    required String name,
    this.sortOrder = const Value.absent(),
    required DateTime lastUsedAt,
    required DateTime createdAt,
    this.color = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        name = Value(name),
        lastUsedAt = Value(lastUsedAt),
        createdAt = Value(createdAt);
  static Insertable<CategoriesTableData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? name,
    Expression<int>? sortOrder,
    Expression<DateTime>? lastUsedAt,
    Expression<DateTime>? createdAt,
    Expression<String>? color,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (lastUsedAt != null) 'last_used_at': lastUsedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (color != null) 'color': color,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? name,
      Value<int>? sortOrder,
      Value<DateTime>? lastUsedAt,
      Value<DateTime>? createdAt,
      Value<String?>? color,
      Value<int>? rowid}) {
    return CategoriesTableCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      createdAt: createdAt ?? this.createdAt,
      color: color ?? this.color,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (lastUsedAt.present) {
      map['last_used_at'] = Variable<DateTime>(lastUsedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesTableCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('color: $color, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NotesTableTable extends NotesTable
    with TableInfo<$NotesTableTable, NotesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
      'category_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
      'body', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _isPrivateMeta =
      const VerificationMeta('isPrivate');
  @override
  late final GeneratedColumn<bool> isPrivate = GeneratedColumn<bool>(
      'is_private', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_private" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _lastUsedAtMeta =
      const VerificationMeta('lastUsedAt');
  @override
  late final GeneratedColumn<DateTime> lastUsedAt = GeneratedColumn<DateTime>(
      'last_used_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _lastOpenedAtMeta =
      const VerificationMeta('lastOpenedAt');
  @override
  late final GeneratedColumn<DateTime> lastOpenedAt = GeneratedColumn<DateTime>(
      'last_opened_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _noteTypeMeta =
      const VerificationMeta('noteType');
  @override
  late final GeneratedColumn<String> noteType = GeneratedColumn<String>(
      'note_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('text'));
  static const VerificationMeta _isPinnedMeta =
      const VerificationMeta('isPinned');
  @override
  late final GeneratedColumn<bool> isPinned = GeneratedColumn<bool>(
      'is_pinned', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_pinned" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _pinnedAtMeta =
      const VerificationMeta('pinnedAt');
  @override
  late final GeneratedColumn<DateTime> pinnedAt = GeneratedColumn<DateTime>(
      'pinned_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _pinOrderMeta =
      const VerificationMeta('pinOrder');
  @override
  late final GeneratedColumn<int> pinOrder = GeneratedColumn<int>(
      'pin_order', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        userId,
        categoryId,
        title,
        body,
        isPrivate,
        lastUsedAt,
        createdAt,
        updatedAt,
        lastOpenedAt,
        noteType,
        isPinned,
        pinnedAt,
        pinOrder
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notes_table';
  @override
  VerificationContext validateIntegrity(Insertable<NotesTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
          _bodyMeta, body.isAcceptableOrUnknown(data['body']!, _bodyMeta));
    }
    if (data.containsKey('is_private')) {
      context.handle(_isPrivateMeta,
          isPrivate.isAcceptableOrUnknown(data['is_private']!, _isPrivateMeta));
    }
    if (data.containsKey('last_used_at')) {
      context.handle(
          _lastUsedAtMeta,
          lastUsedAt.isAcceptableOrUnknown(
              data['last_used_at']!, _lastUsedAtMeta));
    } else if (isInserting) {
      context.missing(_lastUsedAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('last_opened_at')) {
      context.handle(
          _lastOpenedAtMeta,
          lastOpenedAt.isAcceptableOrUnknown(
              data['last_opened_at']!, _lastOpenedAtMeta));
    }
    if (data.containsKey('note_type')) {
      context.handle(_noteTypeMeta,
          noteType.isAcceptableOrUnknown(data['note_type']!, _noteTypeMeta));
    }
    if (data.containsKey('is_pinned')) {
      context.handle(_isPinnedMeta,
          isPinned.isAcceptableOrUnknown(data['is_pinned']!, _isPinnedMeta));
    }
    if (data.containsKey('pinned_at')) {
      context.handle(_pinnedAtMeta,
          pinnedAt.isAcceptableOrUnknown(data['pinned_at']!, _pinnedAtMeta));
    }
    if (data.containsKey('pin_order')) {
      context.handle(_pinOrderMeta,
          pinOrder.isAcceptableOrUnknown(data['pin_order']!, _pinOrderMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NotesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NotesTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      body: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}body'])!,
      isPrivate: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_private'])!,
      lastUsedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_used_at'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      lastOpenedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_opened_at']),
      noteType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note_type'])!,
      isPinned: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_pinned'])!,
      pinnedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}pinned_at']),
      pinOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}pin_order']),
    );
  }

  @override
  $NotesTableTable createAlias(String alias) {
    return $NotesTableTable(attachedDatabase, alias);
  }
}

class NotesTableData extends DataClass implements Insertable<NotesTableData> {
  final String id;
  final String userId;
  final String categoryId;
  final String title;
  final String body;
  final bool isPrivate;
  final DateTime lastUsedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastOpenedAt;
  final String noteType;
  final bool isPinned;
  final DateTime? pinnedAt;
  final int? pinOrder;
  const NotesTableData(
      {required this.id,
      required this.userId,
      required this.categoryId,
      required this.title,
      required this.body,
      required this.isPrivate,
      required this.lastUsedAt,
      required this.createdAt,
      required this.updatedAt,
      this.lastOpenedAt,
      required this.noteType,
      required this.isPinned,
      this.pinnedAt,
      this.pinOrder});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['category_id'] = Variable<String>(categoryId);
    map['title'] = Variable<String>(title);
    map['body'] = Variable<String>(body);
    map['is_private'] = Variable<bool>(isPrivate);
    map['last_used_at'] = Variable<DateTime>(lastUsedAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || lastOpenedAt != null) {
      map['last_opened_at'] = Variable<DateTime>(lastOpenedAt);
    }
    map['note_type'] = Variable<String>(noteType);
    map['is_pinned'] = Variable<bool>(isPinned);
    if (!nullToAbsent || pinnedAt != null) {
      map['pinned_at'] = Variable<DateTime>(pinnedAt);
    }
    if (!nullToAbsent || pinOrder != null) {
      map['pin_order'] = Variable<int>(pinOrder);
    }
    return map;
  }

  NotesTableCompanion toCompanion(bool nullToAbsent) {
    return NotesTableCompanion(
      id: Value(id),
      userId: Value(userId),
      categoryId: Value(categoryId),
      title: Value(title),
      body: Value(body),
      isPrivate: Value(isPrivate),
      lastUsedAt: Value(lastUsedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      lastOpenedAt: lastOpenedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastOpenedAt),
      noteType: Value(noteType),
      isPinned: Value(isPinned),
      pinnedAt: pinnedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(pinnedAt),
      pinOrder: pinOrder == null && nullToAbsent
          ? const Value.absent()
          : Value(pinOrder),
    );
  }

  factory NotesTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NotesTableData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String>(json['body']),
      isPrivate: serializer.fromJson<bool>(json['isPrivate']),
      lastUsedAt: serializer.fromJson<DateTime>(json['lastUsedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      lastOpenedAt: serializer.fromJson<DateTime?>(json['lastOpenedAt']),
      noteType: serializer.fromJson<String>(json['noteType']),
      isPinned: serializer.fromJson<bool>(json['isPinned']),
      pinnedAt: serializer.fromJson<DateTime?>(json['pinnedAt']),
      pinOrder: serializer.fromJson<int?>(json['pinOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'categoryId': serializer.toJson<String>(categoryId),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String>(body),
      'isPrivate': serializer.toJson<bool>(isPrivate),
      'lastUsedAt': serializer.toJson<DateTime>(lastUsedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'lastOpenedAt': serializer.toJson<DateTime?>(lastOpenedAt),
      'noteType': serializer.toJson<String>(noteType),
      'isPinned': serializer.toJson<bool>(isPinned),
      'pinnedAt': serializer.toJson<DateTime?>(pinnedAt),
      'pinOrder': serializer.toJson<int?>(pinOrder),
    };
  }

  NotesTableData copyWith(
          {String? id,
          String? userId,
          String? categoryId,
          String? title,
          String? body,
          bool? isPrivate,
          DateTime? lastUsedAt,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> lastOpenedAt = const Value.absent(),
          String? noteType,
          bool? isPinned,
          Value<DateTime?> pinnedAt = const Value.absent(),
          Value<int?> pinOrder = const Value.absent()}) =>
      NotesTableData(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        categoryId: categoryId ?? this.categoryId,
        title: title ?? this.title,
        body: body ?? this.body,
        isPrivate: isPrivate ?? this.isPrivate,
        lastUsedAt: lastUsedAt ?? this.lastUsedAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        lastOpenedAt:
            lastOpenedAt.present ? lastOpenedAt.value : this.lastOpenedAt,
        noteType: noteType ?? this.noteType,
        isPinned: isPinned ?? this.isPinned,
        pinnedAt: pinnedAt.present ? pinnedAt.value : this.pinnedAt,
        pinOrder: pinOrder.present ? pinOrder.value : this.pinOrder,
      );
  NotesTableData copyWithCompanion(NotesTableCompanion data) {
    return NotesTableData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      isPrivate: data.isPrivate.present ? data.isPrivate.value : this.isPrivate,
      lastUsedAt:
          data.lastUsedAt.present ? data.lastUsedAt.value : this.lastUsedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      lastOpenedAt: data.lastOpenedAt.present
          ? data.lastOpenedAt.value
          : this.lastOpenedAt,
      noteType: data.noteType.present ? data.noteType.value : this.noteType,
      isPinned: data.isPinned.present ? data.isPinned.value : this.isPinned,
      pinnedAt: data.pinnedAt.present ? data.pinnedAt.value : this.pinnedAt,
      pinOrder: data.pinOrder.present ? data.pinOrder.value : this.pinOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NotesTableData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('categoryId: $categoryId, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('isPrivate: $isPrivate, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastOpenedAt: $lastOpenedAt, ')
          ..write('noteType: $noteType, ')
          ..write('isPinned: $isPinned, ')
          ..write('pinnedAt: $pinnedAt, ')
          ..write('pinOrder: $pinOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      userId,
      categoryId,
      title,
      body,
      isPrivate,
      lastUsedAt,
      createdAt,
      updatedAt,
      lastOpenedAt,
      noteType,
      isPinned,
      pinnedAt,
      pinOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotesTableData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.categoryId == this.categoryId &&
          other.title == this.title &&
          other.body == this.body &&
          other.isPrivate == this.isPrivate &&
          other.lastUsedAt == this.lastUsedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.lastOpenedAt == this.lastOpenedAt &&
          other.noteType == this.noteType &&
          other.isPinned == this.isPinned &&
          other.pinnedAt == this.pinnedAt &&
          other.pinOrder == this.pinOrder);
}

class NotesTableCompanion extends UpdateCompanion<NotesTableData> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> categoryId;
  final Value<String> title;
  final Value<String> body;
  final Value<bool> isPrivate;
  final Value<DateTime> lastUsedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> lastOpenedAt;
  final Value<String> noteType;
  final Value<bool> isPinned;
  final Value<DateTime?> pinnedAt;
  final Value<int?> pinOrder;
  final Value<int> rowid;
  const NotesTableCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.isPrivate = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastOpenedAt = const Value.absent(),
    this.noteType = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.pinnedAt = const Value.absent(),
    this.pinOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotesTableCompanion.insert({
    required String id,
    required String userId,
    required String categoryId,
    required String title,
    this.body = const Value.absent(),
    this.isPrivate = const Value.absent(),
    required DateTime lastUsedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.lastOpenedAt = const Value.absent(),
    this.noteType = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.pinnedAt = const Value.absent(),
    this.pinOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        categoryId = Value(categoryId),
        title = Value(title),
        lastUsedAt = Value(lastUsedAt),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<NotesTableData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? categoryId,
    Expression<String>? title,
    Expression<String>? body,
    Expression<bool>? isPrivate,
    Expression<DateTime>? lastUsedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? lastOpenedAt,
    Expression<String>? noteType,
    Expression<bool>? isPinned,
    Expression<DateTime>? pinnedAt,
    Expression<int>? pinOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (categoryId != null) 'category_id': categoryId,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (isPrivate != null) 'is_private': isPrivate,
      if (lastUsedAt != null) 'last_used_at': lastUsedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (lastOpenedAt != null) 'last_opened_at': lastOpenedAt,
      if (noteType != null) 'note_type': noteType,
      if (isPinned != null) 'is_pinned': isPinned,
      if (pinnedAt != null) 'pinned_at': pinnedAt,
      if (pinOrder != null) 'pin_order': pinOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotesTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? categoryId,
      Value<String>? title,
      Value<String>? body,
      Value<bool>? isPrivate,
      Value<DateTime>? lastUsedAt,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? lastOpenedAt,
      Value<String>? noteType,
      Value<bool>? isPinned,
      Value<DateTime?>? pinnedAt,
      Value<int?>? pinOrder,
      Value<int>? rowid}) {
    return NotesTableCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      body: body ?? this.body,
      isPrivate: isPrivate ?? this.isPrivate,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      noteType: noteType ?? this.noteType,
      isPinned: isPinned ?? this.isPinned,
      pinnedAt: pinnedAt ?? this.pinnedAt,
      pinOrder: pinOrder ?? this.pinOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (isPrivate.present) {
      map['is_private'] = Variable<bool>(isPrivate.value);
    }
    if (lastUsedAt.present) {
      map['last_used_at'] = Variable<DateTime>(lastUsedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (lastOpenedAt.present) {
      map['last_opened_at'] = Variable<DateTime>(lastOpenedAt.value);
    }
    if (noteType.present) {
      map['note_type'] = Variable<String>(noteType.value);
    }
    if (isPinned.present) {
      map['is_pinned'] = Variable<bool>(isPinned.value);
    }
    if (pinnedAt.present) {
      map['pinned_at'] = Variable<DateTime>(pinnedAt.value);
    }
    if (pinOrder.present) {
      map['pin_order'] = Variable<int>(pinOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotesTableCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('categoryId: $categoryId, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('isPrivate: $isPrivate, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastOpenedAt: $lastOpenedAt, ')
          ..write('noteType: $noteType, ')
          ..write('isPinned: $isPinned, ')
          ..write('pinnedAt: $pinnedAt, ')
          ..write('pinOrder: $pinOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChecklistItemsTableTable extends ChecklistItemsTable
    with TableInfo<$ChecklistItemsTableTable, ChecklistItemsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChecklistItemsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _noteIdMeta = const VerificationMeta('noteId');
  @override
  late final GeneratedColumn<String> noteId = GeneratedColumn<String>(
      'note_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints:
          'NOT NULL REFERENCES notes_table(id) ON DELETE CASCADE');
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _itemTextMeta =
      const VerificationMeta('itemText');
  @override
  late final GeneratedColumn<String> itemText = GeneratedColumn<String>(
      'text', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isCompletedMeta =
      const VerificationMeta('isCompleted');
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
      'is_completed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_completed" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _completedAtMeta =
      const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
      'completed_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        noteId,
        userId,
        itemText,
        isCompleted,
        sortOrder,
        completedAt,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'checklist_items_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<ChecklistItemsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('note_id')) {
      context.handle(_noteIdMeta,
          noteId.isAcceptableOrUnknown(data['note_id']!, _noteIdMeta));
    } else if (isInserting) {
      context.missing(_noteIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('text')) {
      context.handle(_itemTextMeta,
          itemText.isAcceptableOrUnknown(data['text']!, _itemTextMeta));
    } else if (isInserting) {
      context.missing(_itemTextMeta);
    }
    if (data.containsKey('is_completed')) {
      context.handle(
          _isCompletedMeta,
          isCompleted.isAcceptableOrUnknown(
              data['is_completed']!, _isCompletedMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('completed_at')) {
      context.handle(
          _completedAtMeta,
          completedAt.isAcceptableOrUnknown(
              data['completed_at']!, _completedAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChecklistItemsTableData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChecklistItemsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      noteId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note_id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      itemText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}text'])!,
      isCompleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_completed'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      completedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}completed_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ChecklistItemsTableTable createAlias(String alias) {
    return $ChecklistItemsTableTable(attachedDatabase, alias);
  }
}

class ChecklistItemsTableData extends DataClass
    implements Insertable<ChecklistItemsTableData> {
  final String id;
  final String noteId;
  final String userId;
  final String itemText;
  final bool isCompleted;
  final int sortOrder;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ChecklistItemsTableData(
      {required this.id,
      required this.noteId,
      required this.userId,
      required this.itemText,
      required this.isCompleted,
      required this.sortOrder,
      this.completedAt,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['note_id'] = Variable<String>(noteId);
    map['user_id'] = Variable<String>(userId);
    map['text'] = Variable<String>(itemText);
    map['is_completed'] = Variable<bool>(isCompleted);
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ChecklistItemsTableCompanion toCompanion(bool nullToAbsent) {
    return ChecklistItemsTableCompanion(
      id: Value(id),
      noteId: Value(noteId),
      userId: Value(userId),
      itemText: Value(itemText),
      isCompleted: Value(isCompleted),
      sortOrder: Value(sortOrder),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ChecklistItemsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChecklistItemsTableData(
      id: serializer.fromJson<String>(json['id']),
      noteId: serializer.fromJson<String>(json['noteId']),
      userId: serializer.fromJson<String>(json['userId']),
      itemText: serializer.fromJson<String>(json['itemText']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'noteId': serializer.toJson<String>(noteId),
      'userId': serializer.toJson<String>(userId),
      'itemText': serializer.toJson<String>(itemText),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ChecklistItemsTableData copyWith(
          {String? id,
          String? noteId,
          String? userId,
          String? itemText,
          bool? isCompleted,
          int? sortOrder,
          Value<DateTime?> completedAt = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      ChecklistItemsTableData(
        id: id ?? this.id,
        noteId: noteId ?? this.noteId,
        userId: userId ?? this.userId,
        itemText: itemText ?? this.itemText,
        isCompleted: isCompleted ?? this.isCompleted,
        sortOrder: sortOrder ?? this.sortOrder,
        completedAt: completedAt.present ? completedAt.value : this.completedAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  ChecklistItemsTableData copyWithCompanion(ChecklistItemsTableCompanion data) {
    return ChecklistItemsTableData(
      id: data.id.present ? data.id.value : this.id,
      noteId: data.noteId.present ? data.noteId.value : this.noteId,
      userId: data.userId.present ? data.userId.value : this.userId,
      itemText: data.itemText.present ? data.itemText.value : this.itemText,
      isCompleted:
          data.isCompleted.present ? data.isCompleted.value : this.isCompleted,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      completedAt:
          data.completedAt.present ? data.completedAt.value : this.completedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChecklistItemsTableData(')
          ..write('id: $id, ')
          ..write('noteId: $noteId, ')
          ..write('userId: $userId, ')
          ..write('itemText: $itemText, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('completedAt: $completedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, noteId, userId, itemText, isCompleted,
      sortOrder, completedAt, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChecklistItemsTableData &&
          other.id == this.id &&
          other.noteId == this.noteId &&
          other.userId == this.userId &&
          other.itemText == this.itemText &&
          other.isCompleted == this.isCompleted &&
          other.sortOrder == this.sortOrder &&
          other.completedAt == this.completedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ChecklistItemsTableCompanion
    extends UpdateCompanion<ChecklistItemsTableData> {
  final Value<String> id;
  final Value<String> noteId;
  final Value<String> userId;
  final Value<String> itemText;
  final Value<bool> isCompleted;
  final Value<int> sortOrder;
  final Value<DateTime?> completedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ChecklistItemsTableCompanion({
    this.id = const Value.absent(),
    this.noteId = const Value.absent(),
    this.userId = const Value.absent(),
    this.itemText = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChecklistItemsTableCompanion.insert({
    required String id,
    required String noteId,
    required String userId,
    required String itemText,
    this.isCompleted = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.completedAt = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        noteId = Value(noteId),
        userId = Value(userId),
        itemText = Value(itemText),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<ChecklistItemsTableData> custom({
    Expression<String>? id,
    Expression<String>? noteId,
    Expression<String>? userId,
    Expression<String>? itemText,
    Expression<bool>? isCompleted,
    Expression<int>? sortOrder,
    Expression<DateTime>? completedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (noteId != null) 'note_id': noteId,
      if (userId != null) 'user_id': userId,
      if (itemText != null) 'text': itemText,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (completedAt != null) 'completed_at': completedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChecklistItemsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? noteId,
      Value<String>? userId,
      Value<String>? itemText,
      Value<bool>? isCompleted,
      Value<int>? sortOrder,
      Value<DateTime?>? completedAt,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return ChecklistItemsTableCompanion(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      userId: userId ?? this.userId,
      itemText: itemText ?? this.itemText,
      isCompleted: isCompleted ?? this.isCompleted,
      sortOrder: sortOrder ?? this.sortOrder,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (noteId.present) {
      map['note_id'] = Variable<String>(noteId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (itemText.present) {
      map['text'] = Variable<String>(itemText.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChecklistItemsTableCompanion(')
          ..write('id: $id, ')
          ..write('noteId: $noteId, ')
          ..write('userId: $userId, ')
          ..write('itemText: $itemText, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('completedAt: $completedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AiSearchHistoryTableTable extends AiSearchHistoryTable
    with TableInfo<$AiSearchHistoryTableTable, AiSearchHistoryTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AiSearchHistoryTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _queryHashMeta =
      const VerificationMeta('queryHash');
  @override
  late final GeneratedColumn<String> queryHash = GeneratedColumn<String>(
      'query_hash', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _queryMeta = const VerificationMeta('query');
  @override
  late final GeneratedColumn<String> query = GeneratedColumn<String>(
      'query', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _answerMeta = const VerificationMeta('answer');
  @override
  late final GeneratedColumn<String> answer = GeneratedColumn<String>(
      'answer', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _citedTitlesJsonMeta =
      const VerificationMeta('citedTitlesJson');
  @override
  late final GeneratedColumn<String> citedTitlesJson = GeneratedColumn<String>(
      'cited_titles_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _citedNoteIdsJsonMeta =
      const VerificationMeta('citedNoteIdsJson');
  @override
  late final GeneratedColumn<String> citedNoteIdsJson = GeneratedColumn<String>(
      'cited_note_ids_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [queryHash, query, answer, citedTitlesJson, citedNoteIdsJson, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ai_search_history_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<AiSearchHistoryTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('query_hash')) {
      context.handle(_queryHashMeta,
          queryHash.isAcceptableOrUnknown(data['query_hash']!, _queryHashMeta));
    } else if (isInserting) {
      context.missing(_queryHashMeta);
    }
    if (data.containsKey('query')) {
      context.handle(
          _queryMeta, query.isAcceptableOrUnknown(data['query']!, _queryMeta));
    } else if (isInserting) {
      context.missing(_queryMeta);
    }
    if (data.containsKey('answer')) {
      context.handle(_answerMeta,
          answer.isAcceptableOrUnknown(data['answer']!, _answerMeta));
    } else if (isInserting) {
      context.missing(_answerMeta);
    }
    if (data.containsKey('cited_titles_json')) {
      context.handle(
          _citedTitlesJsonMeta,
          citedTitlesJson.isAcceptableOrUnknown(
              data['cited_titles_json']!, _citedTitlesJsonMeta));
    }
    if (data.containsKey('cited_note_ids_json')) {
      context.handle(
          _citedNoteIdsJsonMeta,
          citedNoteIdsJson.isAcceptableOrUnknown(
              data['cited_note_ids_json']!, _citedNoteIdsJsonMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {queryHash};
  @override
  AiSearchHistoryTableData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AiSearchHistoryTableData(
      queryHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}query_hash'])!,
      query: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}query'])!,
      answer: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}answer'])!,
      citedTitlesJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}cited_titles_json'])!,
      citedNoteIdsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}cited_note_ids_json'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $AiSearchHistoryTableTable createAlias(String alias) {
    return $AiSearchHistoryTableTable(attachedDatabase, alias);
  }
}

class AiSearchHistoryTableData extends DataClass
    implements Insertable<AiSearchHistoryTableData> {
  final String queryHash;
  final String query;
  final String answer;
  final String citedTitlesJson;
  final String citedNoteIdsJson;
  final DateTime createdAt;
  const AiSearchHistoryTableData(
      {required this.queryHash,
      required this.query,
      required this.answer,
      required this.citedTitlesJson,
      required this.citedNoteIdsJson,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['query_hash'] = Variable<String>(queryHash);
    map['query'] = Variable<String>(query);
    map['answer'] = Variable<String>(answer);
    map['cited_titles_json'] = Variable<String>(citedTitlesJson);
    map['cited_note_ids_json'] = Variable<String>(citedNoteIdsJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AiSearchHistoryTableCompanion toCompanion(bool nullToAbsent) {
    return AiSearchHistoryTableCompanion(
      queryHash: Value(queryHash),
      query: Value(query),
      answer: Value(answer),
      citedTitlesJson: Value(citedTitlesJson),
      citedNoteIdsJson: Value(citedNoteIdsJson),
      createdAt: Value(createdAt),
    );
  }

  factory AiSearchHistoryTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AiSearchHistoryTableData(
      queryHash: serializer.fromJson<String>(json['queryHash']),
      query: serializer.fromJson<String>(json['query']),
      answer: serializer.fromJson<String>(json['answer']),
      citedTitlesJson: serializer.fromJson<String>(json['citedTitlesJson']),
      citedNoteIdsJson: serializer.fromJson<String>(json['citedNoteIdsJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'queryHash': serializer.toJson<String>(queryHash),
      'query': serializer.toJson<String>(query),
      'answer': serializer.toJson<String>(answer),
      'citedTitlesJson': serializer.toJson<String>(citedTitlesJson),
      'citedNoteIdsJson': serializer.toJson<String>(citedNoteIdsJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AiSearchHistoryTableData copyWith(
          {String? queryHash,
          String? query,
          String? answer,
          String? citedTitlesJson,
          String? citedNoteIdsJson,
          DateTime? createdAt}) =>
      AiSearchHistoryTableData(
        queryHash: queryHash ?? this.queryHash,
        query: query ?? this.query,
        answer: answer ?? this.answer,
        citedTitlesJson: citedTitlesJson ?? this.citedTitlesJson,
        citedNoteIdsJson: citedNoteIdsJson ?? this.citedNoteIdsJson,
        createdAt: createdAt ?? this.createdAt,
      );
  AiSearchHistoryTableData copyWithCompanion(
      AiSearchHistoryTableCompanion data) {
    return AiSearchHistoryTableData(
      queryHash: data.queryHash.present ? data.queryHash.value : this.queryHash,
      query: data.query.present ? data.query.value : this.query,
      answer: data.answer.present ? data.answer.value : this.answer,
      citedTitlesJson: data.citedTitlesJson.present
          ? data.citedTitlesJson.value
          : this.citedTitlesJson,
      citedNoteIdsJson: data.citedNoteIdsJson.present
          ? data.citedNoteIdsJson.value
          : this.citedNoteIdsJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AiSearchHistoryTableData(')
          ..write('queryHash: $queryHash, ')
          ..write('query: $query, ')
          ..write('answer: $answer, ')
          ..write('citedTitlesJson: $citedTitlesJson, ')
          ..write('citedNoteIdsJson: $citedNoteIdsJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      queryHash, query, answer, citedTitlesJson, citedNoteIdsJson, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AiSearchHistoryTableData &&
          other.queryHash == this.queryHash &&
          other.query == this.query &&
          other.answer == this.answer &&
          other.citedTitlesJson == this.citedTitlesJson &&
          other.citedNoteIdsJson == this.citedNoteIdsJson &&
          other.createdAt == this.createdAt);
}

class AiSearchHistoryTableCompanion
    extends UpdateCompanion<AiSearchHistoryTableData> {
  final Value<String> queryHash;
  final Value<String> query;
  final Value<String> answer;
  final Value<String> citedTitlesJson;
  final Value<String> citedNoteIdsJson;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const AiSearchHistoryTableCompanion({
    this.queryHash = const Value.absent(),
    this.query = const Value.absent(),
    this.answer = const Value.absent(),
    this.citedTitlesJson = const Value.absent(),
    this.citedNoteIdsJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AiSearchHistoryTableCompanion.insert({
    required String queryHash,
    required String query,
    required String answer,
    this.citedTitlesJson = const Value.absent(),
    this.citedNoteIdsJson = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : queryHash = Value(queryHash),
        query = Value(query),
        answer = Value(answer),
        createdAt = Value(createdAt);
  static Insertable<AiSearchHistoryTableData> custom({
    Expression<String>? queryHash,
    Expression<String>? query,
    Expression<String>? answer,
    Expression<String>? citedTitlesJson,
    Expression<String>? citedNoteIdsJson,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (queryHash != null) 'query_hash': queryHash,
      if (query != null) 'query': query,
      if (answer != null) 'answer': answer,
      if (citedTitlesJson != null) 'cited_titles_json': citedTitlesJson,
      if (citedNoteIdsJson != null) 'cited_note_ids_json': citedNoteIdsJson,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AiSearchHistoryTableCompanion copyWith(
      {Value<String>? queryHash,
      Value<String>? query,
      Value<String>? answer,
      Value<String>? citedTitlesJson,
      Value<String>? citedNoteIdsJson,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return AiSearchHistoryTableCompanion(
      queryHash: queryHash ?? this.queryHash,
      query: query ?? this.query,
      answer: answer ?? this.answer,
      citedTitlesJson: citedTitlesJson ?? this.citedTitlesJson,
      citedNoteIdsJson: citedNoteIdsJson ?? this.citedNoteIdsJson,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (queryHash.present) {
      map['query_hash'] = Variable<String>(queryHash.value);
    }
    if (query.present) {
      map['query'] = Variable<String>(query.value);
    }
    if (answer.present) {
      map['answer'] = Variable<String>(answer.value);
    }
    if (citedTitlesJson.present) {
      map['cited_titles_json'] = Variable<String>(citedTitlesJson.value);
    }
    if (citedNoteIdsJson.present) {
      map['cited_note_ids_json'] = Variable<String>(citedNoteIdsJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AiSearchHistoryTableCompanion(')
          ..write('queryHash: $queryHash, ')
          ..write('query: $query, ')
          ..write('answer: $answer, ')
          ..write('citedTitlesJson: $citedTitlesJson, ')
          ..write('citedNoteIdsJson: $citedNoteIdsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AiCacheTableTable extends AiCacheTable
    with TableInfo<$AiCacheTableTable, AiCacheTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AiCacheTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _queryHashMeta =
      const VerificationMeta('queryHash');
  @override
  late final GeneratedColumn<String> queryHash = GeneratedColumn<String>(
      'query_hash', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _responseMeta =
      const VerificationMeta('response');
  @override
  late final GeneratedColumn<String> response = GeneratedColumn<String>(
      'response', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _cachedAtMeta =
      const VerificationMeta('cachedAt');
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
      'cached_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [queryHash, response, cachedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ai_cache_table';
  @override
  VerificationContext validateIntegrity(Insertable<AiCacheTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('query_hash')) {
      context.handle(_queryHashMeta,
          queryHash.isAcceptableOrUnknown(data['query_hash']!, _queryHashMeta));
    } else if (isInserting) {
      context.missing(_queryHashMeta);
    }
    if (data.containsKey('response')) {
      context.handle(_responseMeta,
          response.isAcceptableOrUnknown(data['response']!, _responseMeta));
    } else if (isInserting) {
      context.missing(_responseMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(_cachedAtMeta,
          cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta));
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {queryHash};
  @override
  AiCacheTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AiCacheTableData(
      queryHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}query_hash'])!,
      response: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}response'])!,
      cachedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}cached_at'])!,
    );
  }

  @override
  $AiCacheTableTable createAlias(String alias) {
    return $AiCacheTableTable(attachedDatabase, alias);
  }
}

class AiCacheTableData extends DataClass
    implements Insertable<AiCacheTableData> {
  final String queryHash;
  final String response;
  final DateTime cachedAt;
  const AiCacheTableData(
      {required this.queryHash,
      required this.response,
      required this.cachedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['query_hash'] = Variable<String>(queryHash);
    map['response'] = Variable<String>(response);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  AiCacheTableCompanion toCompanion(bool nullToAbsent) {
    return AiCacheTableCompanion(
      queryHash: Value(queryHash),
      response: Value(response),
      cachedAt: Value(cachedAt),
    );
  }

  factory AiCacheTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AiCacheTableData(
      queryHash: serializer.fromJson<String>(json['queryHash']),
      response: serializer.fromJson<String>(json['response']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'queryHash': serializer.toJson<String>(queryHash),
      'response': serializer.toJson<String>(response),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  AiCacheTableData copyWith(
          {String? queryHash, String? response, DateTime? cachedAt}) =>
      AiCacheTableData(
        queryHash: queryHash ?? this.queryHash,
        response: response ?? this.response,
        cachedAt: cachedAt ?? this.cachedAt,
      );
  AiCacheTableData copyWithCompanion(AiCacheTableCompanion data) {
    return AiCacheTableData(
      queryHash: data.queryHash.present ? data.queryHash.value : this.queryHash,
      response: data.response.present ? data.response.value : this.response,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AiCacheTableData(')
          ..write('queryHash: $queryHash, ')
          ..write('response: $response, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(queryHash, response, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AiCacheTableData &&
          other.queryHash == this.queryHash &&
          other.response == this.response &&
          other.cachedAt == this.cachedAt);
}

class AiCacheTableCompanion extends UpdateCompanion<AiCacheTableData> {
  final Value<String> queryHash;
  final Value<String> response;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const AiCacheTableCompanion({
    this.queryHash = const Value.absent(),
    this.response = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AiCacheTableCompanion.insert({
    required String queryHash,
    required String response,
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  })  : queryHash = Value(queryHash),
        response = Value(response),
        cachedAt = Value(cachedAt);
  static Insertable<AiCacheTableData> custom({
    Expression<String>? queryHash,
    Expression<String>? response,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (queryHash != null) 'query_hash': queryHash,
      if (response != null) 'response': response,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AiCacheTableCompanion copyWith(
      {Value<String>? queryHash,
      Value<String>? response,
      Value<DateTime>? cachedAt,
      Value<int>? rowid}) {
    return AiCacheTableCompanion(
      queryHash: queryHash ?? this.queryHash,
      response: response ?? this.response,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (queryHash.present) {
      map['query_hash'] = Variable<String>(queryHash.value);
    }
    if (response.present) {
      map['response'] = Variable<String>(response.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AiCacheTableCompanion(')
          ..write('queryHash: $queryHash, ')
          ..write('response: $response, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingOpsTableTable extends PendingOpsTable
    with TableInfo<$PendingOpsTableTable, PendingOpsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingOpsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _opTypeMeta = const VerificationMeta('opType');
  @override
  late final GeneratedColumn<String> opType = GeneratedColumn<String>(
      'op_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _recordIdMeta =
      const VerificationMeta('recordId');
  @override
  late final GeneratedColumn<String> recordId = GeneratedColumn<String>(
      'record_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, opType, recordId, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_ops_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<PendingOpsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('op_type')) {
      context.handle(_opTypeMeta,
          opType.isAcceptableOrUnknown(data['op_type']!, _opTypeMeta));
    } else if (isInserting) {
      context.missing(_opTypeMeta);
    }
    if (data.containsKey('record_id')) {
      context.handle(_recordIdMeta,
          recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta));
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingOpsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingOpsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      opType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}op_type'])!,
      recordId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}record_id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $PendingOpsTableTable createAlias(String alias) {
    return $PendingOpsTableTable(attachedDatabase, alias);
  }
}

class PendingOpsTableData extends DataClass
    implements Insertable<PendingOpsTableData> {
  final String id;
  final String opType;
  final String recordId;
  final DateTime createdAt;
  const PendingOpsTableData(
      {required this.id,
      required this.opType,
      required this.recordId,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['op_type'] = Variable<String>(opType);
    map['record_id'] = Variable<String>(recordId);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PendingOpsTableCompanion toCompanion(bool nullToAbsent) {
    return PendingOpsTableCompanion(
      id: Value(id),
      opType: Value(opType),
      recordId: Value(recordId),
      createdAt: Value(createdAt),
    );
  }

  factory PendingOpsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingOpsTableData(
      id: serializer.fromJson<String>(json['id']),
      opType: serializer.fromJson<String>(json['opType']),
      recordId: serializer.fromJson<String>(json['recordId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'opType': serializer.toJson<String>(opType),
      'recordId': serializer.toJson<String>(recordId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PendingOpsTableData copyWith(
          {String? id,
          String? opType,
          String? recordId,
          DateTime? createdAt}) =>
      PendingOpsTableData(
        id: id ?? this.id,
        opType: opType ?? this.opType,
        recordId: recordId ?? this.recordId,
        createdAt: createdAt ?? this.createdAt,
      );
  PendingOpsTableData copyWithCompanion(PendingOpsTableCompanion data) {
    return PendingOpsTableData(
      id: data.id.present ? data.id.value : this.id,
      opType: data.opType.present ? data.opType.value : this.opType,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingOpsTableData(')
          ..write('id: $id, ')
          ..write('opType: $opType, ')
          ..write('recordId: $recordId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, opType, recordId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingOpsTableData &&
          other.id == this.id &&
          other.opType == this.opType &&
          other.recordId == this.recordId &&
          other.createdAt == this.createdAt);
}

class PendingOpsTableCompanion extends UpdateCompanion<PendingOpsTableData> {
  final Value<String> id;
  final Value<String> opType;
  final Value<String> recordId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const PendingOpsTableCompanion({
    this.id = const Value.absent(),
    this.opType = const Value.absent(),
    this.recordId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PendingOpsTableCompanion.insert({
    required String id,
    required String opType,
    required String recordId,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        opType = Value(opType),
        recordId = Value(recordId),
        createdAt = Value(createdAt);
  static Insertable<PendingOpsTableData> custom({
    Expression<String>? id,
    Expression<String>? opType,
    Expression<String>? recordId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (opType != null) 'op_type': opType,
      if (recordId != null) 'record_id': recordId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PendingOpsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? opType,
      Value<String>? recordId,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return PendingOpsTableCompanion(
      id: id ?? this.id,
      opType: opType ?? this.opType,
      recordId: recordId ?? this.recordId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (opType.present) {
      map['op_type'] = Variable<String>(opType.value);
    }
    if (recordId.present) {
      map['record_id'] = Variable<String>(recordId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingOpsTableCompanion(')
          ..write('id: $id, ')
          ..write('opType: $opType, ')
          ..write('recordId: $recordId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CategoriesTableTable categoriesTable =
      $CategoriesTableTable(this);
  late final $NotesTableTable notesTable = $NotesTableTable(this);
  late final $ChecklistItemsTableTable checklistItemsTable =
      $ChecklistItemsTableTable(this);
  late final $AiSearchHistoryTableTable aiSearchHistoryTable =
      $AiSearchHistoryTableTable(this);
  late final $AiCacheTableTable aiCacheTable = $AiCacheTableTable(this);
  late final $PendingOpsTableTable pendingOpsTable =
      $PendingOpsTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        categoriesTable,
        notesTable,
        checklistItemsTable,
        aiSearchHistoryTable,
        aiCacheTable,
        pendingOpsTable
      ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('notes_table',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('checklist_items_table', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$CategoriesTableTableCreateCompanionBuilder = CategoriesTableCompanion
    Function({
  required String id,
  required String userId,
  required String name,
  Value<int> sortOrder,
  required DateTime lastUsedAt,
  required DateTime createdAt,
  Value<String?> color,
  Value<int> rowid,
});
typedef $$CategoriesTableTableUpdateCompanionBuilder = CategoriesTableCompanion
    Function({
  Value<String> id,
  Value<String> userId,
  Value<String> name,
  Value<int> sortOrder,
  Value<DateTime> lastUsedAt,
  Value<DateTime> createdAt,
  Value<String?> color,
  Value<int> rowid,
});

class $$CategoriesTableTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTableTable> {
  $$CategoriesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastUsedAt => $composableBuilder(
      column: $table.lastUsedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnFilters(column));
}

class $$CategoriesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTableTable> {
  $$CategoriesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastUsedAt => $composableBuilder(
      column: $table.lastUsedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnOrderings(column));
}

class $$CategoriesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTableTable> {
  $$CategoriesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUsedAt => $composableBuilder(
      column: $table.lastUsedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);
}

class $$CategoriesTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CategoriesTableTable,
    CategoriesTableData,
    $$CategoriesTableTableFilterComposer,
    $$CategoriesTableTableOrderingComposer,
    $$CategoriesTableTableAnnotationComposer,
    $$CategoriesTableTableCreateCompanionBuilder,
    $$CategoriesTableTableUpdateCompanionBuilder,
    (
      CategoriesTableData,
      BaseReferences<_$AppDatabase, $CategoriesTableTable, CategoriesTableData>
    ),
    CategoriesTableData,
    PrefetchHooks Function()> {
  $$CategoriesTableTableTableManager(
      _$AppDatabase db, $CategoriesTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<DateTime> lastUsedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<String?> color = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoriesTableCompanion(
            id: id,
            userId: userId,
            name: name,
            sortOrder: sortOrder,
            lastUsedAt: lastUsedAt,
            createdAt: createdAt,
            color: color,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String name,
            Value<int> sortOrder = const Value.absent(),
            required DateTime lastUsedAt,
            required DateTime createdAt,
            Value<String?> color = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoriesTableCompanion.insert(
            id: id,
            userId: userId,
            name: name,
            sortOrder: sortOrder,
            lastUsedAt: lastUsedAt,
            createdAt: createdAt,
            color: color,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CategoriesTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CategoriesTableTable,
    CategoriesTableData,
    $$CategoriesTableTableFilterComposer,
    $$CategoriesTableTableOrderingComposer,
    $$CategoriesTableTableAnnotationComposer,
    $$CategoriesTableTableCreateCompanionBuilder,
    $$CategoriesTableTableUpdateCompanionBuilder,
    (
      CategoriesTableData,
      BaseReferences<_$AppDatabase, $CategoriesTableTable, CategoriesTableData>
    ),
    CategoriesTableData,
    PrefetchHooks Function()>;
typedef $$NotesTableTableCreateCompanionBuilder = NotesTableCompanion Function({
  required String id,
  required String userId,
  required String categoryId,
  required String title,
  Value<String> body,
  Value<bool> isPrivate,
  required DateTime lastUsedAt,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> lastOpenedAt,
  Value<String> noteType,
  Value<bool> isPinned,
  Value<DateTime?> pinnedAt,
  Value<int?> pinOrder,
  Value<int> rowid,
});
typedef $$NotesTableTableUpdateCompanionBuilder = NotesTableCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String> categoryId,
  Value<String> title,
  Value<String> body,
  Value<bool> isPrivate,
  Value<DateTime> lastUsedAt,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> lastOpenedAt,
  Value<String> noteType,
  Value<bool> isPinned,
  Value<DateTime?> pinnedAt,
  Value<int?> pinOrder,
  Value<int> rowid,
});

final class $$NotesTableTableReferences
    extends BaseReferences<_$AppDatabase, $NotesTableTable, NotesTableData> {
  $$NotesTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ChecklistItemsTableTable,
      List<ChecklistItemsTableData>> _checklistItemsTableRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.checklistItemsTable,
          aliasName: $_aliasNameGenerator(
              db.notesTable.id, db.checklistItemsTable.noteId));

  $$ChecklistItemsTableTableProcessedTableManager get checklistItemsTableRefs {
    final manager =
        $$ChecklistItemsTableTableTableManager($_db, $_db.checklistItemsTable)
            .filter((f) => f.noteId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_checklistItemsTableRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$NotesTableTableFilterComposer
    extends Composer<_$AppDatabase, $NotesTableTable> {
  $$NotesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isPrivate => $composableBuilder(
      column: $table.isPrivate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastUsedAt => $composableBuilder(
      column: $table.lastUsedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastOpenedAt => $composableBuilder(
      column: $table.lastOpenedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get noteType => $composableBuilder(
      column: $table.noteType, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isPinned => $composableBuilder(
      column: $table.isPinned, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get pinnedAt => $composableBuilder(
      column: $table.pinnedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get pinOrder => $composableBuilder(
      column: $table.pinOrder, builder: (column) => ColumnFilters(column));

  Expression<bool> checklistItemsTableRefs(
      Expression<bool> Function($$ChecklistItemsTableTableFilterComposer f) f) {
    final $$ChecklistItemsTableTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.checklistItemsTable,
        getReferencedColumn: (t) => t.noteId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChecklistItemsTableTableFilterComposer(
              $db: $db,
              $table: $db.checklistItemsTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$NotesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $NotesTableTable> {
  $$NotesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isPrivate => $composableBuilder(
      column: $table.isPrivate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastUsedAt => $composableBuilder(
      column: $table.lastUsedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastOpenedAt => $composableBuilder(
      column: $table.lastOpenedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get noteType => $composableBuilder(
      column: $table.noteType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isPinned => $composableBuilder(
      column: $table.isPinned, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get pinnedAt => $composableBuilder(
      column: $table.pinnedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get pinOrder => $composableBuilder(
      column: $table.pinOrder, builder: (column) => ColumnOrderings(column));
}

class $$NotesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotesTableTable> {
  $$NotesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<bool> get isPrivate =>
      $composableBuilder(column: $table.isPrivate, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUsedAt => $composableBuilder(
      column: $table.lastUsedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastOpenedAt => $composableBuilder(
      column: $table.lastOpenedAt, builder: (column) => column);

  GeneratedColumn<String> get noteType =>
      $composableBuilder(column: $table.noteType, builder: (column) => column);

  GeneratedColumn<bool> get isPinned =>
      $composableBuilder(column: $table.isPinned, builder: (column) => column);

  GeneratedColumn<DateTime> get pinnedAt =>
      $composableBuilder(column: $table.pinnedAt, builder: (column) => column);

  GeneratedColumn<int> get pinOrder =>
      $composableBuilder(column: $table.pinOrder, builder: (column) => column);

  Expression<T> checklistItemsTableRefs<T extends Object>(
      Expression<T> Function($$ChecklistItemsTableTableAnnotationComposer a)
          f) {
    final $$ChecklistItemsTableTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.checklistItemsTable,
            getReferencedColumn: (t) => t.noteId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$ChecklistItemsTableTableAnnotationComposer(
                  $db: $db,
                  $table: $db.checklistItemsTable,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$NotesTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $NotesTableTable,
    NotesTableData,
    $$NotesTableTableFilterComposer,
    $$NotesTableTableOrderingComposer,
    $$NotesTableTableAnnotationComposer,
    $$NotesTableTableCreateCompanionBuilder,
    $$NotesTableTableUpdateCompanionBuilder,
    (NotesTableData, $$NotesTableTableReferences),
    NotesTableData,
    PrefetchHooks Function({bool checklistItemsTableRefs})> {
  $$NotesTableTableTableManager(_$AppDatabase db, $NotesTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> categoryId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> body = const Value.absent(),
            Value<bool> isPrivate = const Value.absent(),
            Value<DateTime> lastUsedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> lastOpenedAt = const Value.absent(),
            Value<String> noteType = const Value.absent(),
            Value<bool> isPinned = const Value.absent(),
            Value<DateTime?> pinnedAt = const Value.absent(),
            Value<int?> pinOrder = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              NotesTableCompanion(
            id: id,
            userId: userId,
            categoryId: categoryId,
            title: title,
            body: body,
            isPrivate: isPrivate,
            lastUsedAt: lastUsedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            lastOpenedAt: lastOpenedAt,
            noteType: noteType,
            isPinned: isPinned,
            pinnedAt: pinnedAt,
            pinOrder: pinOrder,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String categoryId,
            required String title,
            Value<String> body = const Value.absent(),
            Value<bool> isPrivate = const Value.absent(),
            required DateTime lastUsedAt,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> lastOpenedAt = const Value.absent(),
            Value<String> noteType = const Value.absent(),
            Value<bool> isPinned = const Value.absent(),
            Value<DateTime?> pinnedAt = const Value.absent(),
            Value<int?> pinOrder = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              NotesTableCompanion.insert(
            id: id,
            userId: userId,
            categoryId: categoryId,
            title: title,
            body: body,
            isPrivate: isPrivate,
            lastUsedAt: lastUsedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            lastOpenedAt: lastOpenedAt,
            noteType: noteType,
            isPinned: isPinned,
            pinnedAt: pinnedAt,
            pinOrder: pinOrder,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$NotesTableTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({checklistItemsTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (checklistItemsTableRefs) db.checklistItemsTable
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (checklistItemsTableRefs)
                    await $_getPrefetchedData<NotesTableData, $NotesTableTable,
                            ChecklistItemsTableData>(
                        currentTable: table,
                        referencedTable: $$NotesTableTableReferences
                            ._checklistItemsTableRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$NotesTableTableReferences(db, table, p0)
                                .checklistItemsTableRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.noteId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$NotesTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $NotesTableTable,
    NotesTableData,
    $$NotesTableTableFilterComposer,
    $$NotesTableTableOrderingComposer,
    $$NotesTableTableAnnotationComposer,
    $$NotesTableTableCreateCompanionBuilder,
    $$NotesTableTableUpdateCompanionBuilder,
    (NotesTableData, $$NotesTableTableReferences),
    NotesTableData,
    PrefetchHooks Function({bool checklistItemsTableRefs})>;
typedef $$ChecklistItemsTableTableCreateCompanionBuilder
    = ChecklistItemsTableCompanion Function({
  required String id,
  required String noteId,
  required String userId,
  required String itemText,
  Value<bool> isCompleted,
  Value<int> sortOrder,
  Value<DateTime?> completedAt,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$ChecklistItemsTableTableUpdateCompanionBuilder
    = ChecklistItemsTableCompanion Function({
  Value<String> id,
  Value<String> noteId,
  Value<String> userId,
  Value<String> itemText,
  Value<bool> isCompleted,
  Value<int> sortOrder,
  Value<DateTime?> completedAt,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$ChecklistItemsTableTableReferences extends BaseReferences<
    _$AppDatabase, $ChecklistItemsTableTable, ChecklistItemsTableData> {
  $$ChecklistItemsTableTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $NotesTableTable _noteIdTable(_$AppDatabase db) =>
      db.notesTable.createAlias($_aliasNameGenerator(
          db.checklistItemsTable.noteId, db.notesTable.id));

  $$NotesTableTableProcessedTableManager get noteId {
    final $_column = $_itemColumn<String>('note_id')!;

    final manager = $$NotesTableTableTableManager($_db, $_db.notesTable)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_noteIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ChecklistItemsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ChecklistItemsTableTable> {
  $$ChecklistItemsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get itemText => $composableBuilder(
      column: $table.itemText, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$NotesTableTableFilterComposer get noteId {
    final $$NotesTableTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.noteId,
        referencedTable: $db.notesTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NotesTableTableFilterComposer(
              $db: $db,
              $table: $db.notesTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ChecklistItemsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ChecklistItemsTableTable> {
  $$ChecklistItemsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get itemText => $composableBuilder(
      column: $table.itemText, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$NotesTableTableOrderingComposer get noteId {
    final $$NotesTableTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.noteId,
        referencedTable: $db.notesTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NotesTableTableOrderingComposer(
              $db: $db,
              $table: $db.notesTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ChecklistItemsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChecklistItemsTableTable> {
  $$ChecklistItemsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get itemText =>
      $composableBuilder(column: $table.itemText, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$NotesTableTableAnnotationComposer get noteId {
    final $$NotesTableTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.noteId,
        referencedTable: $db.notesTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NotesTableTableAnnotationComposer(
              $db: $db,
              $table: $db.notesTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ChecklistItemsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ChecklistItemsTableTable,
    ChecklistItemsTableData,
    $$ChecklistItemsTableTableFilterComposer,
    $$ChecklistItemsTableTableOrderingComposer,
    $$ChecklistItemsTableTableAnnotationComposer,
    $$ChecklistItemsTableTableCreateCompanionBuilder,
    $$ChecklistItemsTableTableUpdateCompanionBuilder,
    (ChecklistItemsTableData, $$ChecklistItemsTableTableReferences),
    ChecklistItemsTableData,
    PrefetchHooks Function({bool noteId})> {
  $$ChecklistItemsTableTableTableManager(
      _$AppDatabase db, $ChecklistItemsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChecklistItemsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChecklistItemsTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChecklistItemsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> noteId = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> itemText = const Value.absent(),
            Value<bool> isCompleted = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<DateTime?> completedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ChecklistItemsTableCompanion(
            id: id,
            noteId: noteId,
            userId: userId,
            itemText: itemText,
            isCompleted: isCompleted,
            sortOrder: sortOrder,
            completedAt: completedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String noteId,
            required String userId,
            required String itemText,
            Value<bool> isCompleted = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<DateTime?> completedAt = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ChecklistItemsTableCompanion.insert(
            id: id,
            noteId: noteId,
            userId: userId,
            itemText: itemText,
            isCompleted: isCompleted,
            sortOrder: sortOrder,
            completedAt: completedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ChecklistItemsTableTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({noteId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (noteId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.noteId,
                    referencedTable:
                        $$ChecklistItemsTableTableReferences._noteIdTable(db),
                    referencedColumn: $$ChecklistItemsTableTableReferences
                        ._noteIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ChecklistItemsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ChecklistItemsTableTable,
    ChecklistItemsTableData,
    $$ChecklistItemsTableTableFilterComposer,
    $$ChecklistItemsTableTableOrderingComposer,
    $$ChecklistItemsTableTableAnnotationComposer,
    $$ChecklistItemsTableTableCreateCompanionBuilder,
    $$ChecklistItemsTableTableUpdateCompanionBuilder,
    (ChecklistItemsTableData, $$ChecklistItemsTableTableReferences),
    ChecklistItemsTableData,
    PrefetchHooks Function({bool noteId})>;
typedef $$AiSearchHistoryTableTableCreateCompanionBuilder
    = AiSearchHistoryTableCompanion Function({
  required String queryHash,
  required String query,
  required String answer,
  Value<String> citedTitlesJson,
  Value<String> citedNoteIdsJson,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$AiSearchHistoryTableTableUpdateCompanionBuilder
    = AiSearchHistoryTableCompanion Function({
  Value<String> queryHash,
  Value<String> query,
  Value<String> answer,
  Value<String> citedTitlesJson,
  Value<String> citedNoteIdsJson,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$AiSearchHistoryTableTableFilterComposer
    extends Composer<_$AppDatabase, $AiSearchHistoryTableTable> {
  $$AiSearchHistoryTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get queryHash => $composableBuilder(
      column: $table.queryHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get query => $composableBuilder(
      column: $table.query, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get answer => $composableBuilder(
      column: $table.answer, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get citedTitlesJson => $composableBuilder(
      column: $table.citedTitlesJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get citedNoteIdsJson => $composableBuilder(
      column: $table.citedNoteIdsJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$AiSearchHistoryTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AiSearchHistoryTableTable> {
  $$AiSearchHistoryTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get queryHash => $composableBuilder(
      column: $table.queryHash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get query => $composableBuilder(
      column: $table.query, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get answer => $composableBuilder(
      column: $table.answer, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get citedTitlesJson => $composableBuilder(
      column: $table.citedTitlesJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get citedNoteIdsJson => $composableBuilder(
      column: $table.citedNoteIdsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$AiSearchHistoryTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AiSearchHistoryTableTable> {
  $$AiSearchHistoryTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get queryHash =>
      $composableBuilder(column: $table.queryHash, builder: (column) => column);

  GeneratedColumn<String> get query =>
      $composableBuilder(column: $table.query, builder: (column) => column);

  GeneratedColumn<String> get answer =>
      $composableBuilder(column: $table.answer, builder: (column) => column);

  GeneratedColumn<String> get citedTitlesJson => $composableBuilder(
      column: $table.citedTitlesJson, builder: (column) => column);

  GeneratedColumn<String> get citedNoteIdsJson => $composableBuilder(
      column: $table.citedNoteIdsJson, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$AiSearchHistoryTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AiSearchHistoryTableTable,
    AiSearchHistoryTableData,
    $$AiSearchHistoryTableTableFilterComposer,
    $$AiSearchHistoryTableTableOrderingComposer,
    $$AiSearchHistoryTableTableAnnotationComposer,
    $$AiSearchHistoryTableTableCreateCompanionBuilder,
    $$AiSearchHistoryTableTableUpdateCompanionBuilder,
    (
      AiSearchHistoryTableData,
      BaseReferences<_$AppDatabase, $AiSearchHistoryTableTable,
          AiSearchHistoryTableData>
    ),
    AiSearchHistoryTableData,
    PrefetchHooks Function()> {
  $$AiSearchHistoryTableTableTableManager(
      _$AppDatabase db, $AiSearchHistoryTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AiSearchHistoryTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AiSearchHistoryTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AiSearchHistoryTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> queryHash = const Value.absent(),
            Value<String> query = const Value.absent(),
            Value<String> answer = const Value.absent(),
            Value<String> citedTitlesJson = const Value.absent(),
            Value<String> citedNoteIdsJson = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AiSearchHistoryTableCompanion(
            queryHash: queryHash,
            query: query,
            answer: answer,
            citedTitlesJson: citedTitlesJson,
            citedNoteIdsJson: citedNoteIdsJson,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String queryHash,
            required String query,
            required String answer,
            Value<String> citedTitlesJson = const Value.absent(),
            Value<String> citedNoteIdsJson = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              AiSearchHistoryTableCompanion.insert(
            queryHash: queryHash,
            query: query,
            answer: answer,
            citedTitlesJson: citedTitlesJson,
            citedNoteIdsJson: citedNoteIdsJson,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AiSearchHistoryTableTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $AiSearchHistoryTableTable,
        AiSearchHistoryTableData,
        $$AiSearchHistoryTableTableFilterComposer,
        $$AiSearchHistoryTableTableOrderingComposer,
        $$AiSearchHistoryTableTableAnnotationComposer,
        $$AiSearchHistoryTableTableCreateCompanionBuilder,
        $$AiSearchHistoryTableTableUpdateCompanionBuilder,
        (
          AiSearchHistoryTableData,
          BaseReferences<_$AppDatabase, $AiSearchHistoryTableTable,
              AiSearchHistoryTableData>
        ),
        AiSearchHistoryTableData,
        PrefetchHooks Function()>;
typedef $$AiCacheTableTableCreateCompanionBuilder = AiCacheTableCompanion
    Function({
  required String queryHash,
  required String response,
  required DateTime cachedAt,
  Value<int> rowid,
});
typedef $$AiCacheTableTableUpdateCompanionBuilder = AiCacheTableCompanion
    Function({
  Value<String> queryHash,
  Value<String> response,
  Value<DateTime> cachedAt,
  Value<int> rowid,
});

class $$AiCacheTableTableFilterComposer
    extends Composer<_$AppDatabase, $AiCacheTableTable> {
  $$AiCacheTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get queryHash => $composableBuilder(
      column: $table.queryHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get response => $composableBuilder(
      column: $table.response, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnFilters(column));
}

class $$AiCacheTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AiCacheTableTable> {
  $$AiCacheTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get queryHash => $composableBuilder(
      column: $table.queryHash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get response => $composableBuilder(
      column: $table.response, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnOrderings(column));
}

class $$AiCacheTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AiCacheTableTable> {
  $$AiCacheTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get queryHash =>
      $composableBuilder(column: $table.queryHash, builder: (column) => column);

  GeneratedColumn<String> get response =>
      $composableBuilder(column: $table.response, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$AiCacheTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AiCacheTableTable,
    AiCacheTableData,
    $$AiCacheTableTableFilterComposer,
    $$AiCacheTableTableOrderingComposer,
    $$AiCacheTableTableAnnotationComposer,
    $$AiCacheTableTableCreateCompanionBuilder,
    $$AiCacheTableTableUpdateCompanionBuilder,
    (
      AiCacheTableData,
      BaseReferences<_$AppDatabase, $AiCacheTableTable, AiCacheTableData>
    ),
    AiCacheTableData,
    PrefetchHooks Function()> {
  $$AiCacheTableTableTableManager(_$AppDatabase db, $AiCacheTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AiCacheTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AiCacheTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AiCacheTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> queryHash = const Value.absent(),
            Value<String> response = const Value.absent(),
            Value<DateTime> cachedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AiCacheTableCompanion(
            queryHash: queryHash,
            response: response,
            cachedAt: cachedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String queryHash,
            required String response,
            required DateTime cachedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              AiCacheTableCompanion.insert(
            queryHash: queryHash,
            response: response,
            cachedAt: cachedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AiCacheTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AiCacheTableTable,
    AiCacheTableData,
    $$AiCacheTableTableFilterComposer,
    $$AiCacheTableTableOrderingComposer,
    $$AiCacheTableTableAnnotationComposer,
    $$AiCacheTableTableCreateCompanionBuilder,
    $$AiCacheTableTableUpdateCompanionBuilder,
    (
      AiCacheTableData,
      BaseReferences<_$AppDatabase, $AiCacheTableTable, AiCacheTableData>
    ),
    AiCacheTableData,
    PrefetchHooks Function()>;
typedef $$PendingOpsTableTableCreateCompanionBuilder = PendingOpsTableCompanion
    Function({
  required String id,
  required String opType,
  required String recordId,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$PendingOpsTableTableUpdateCompanionBuilder = PendingOpsTableCompanion
    Function({
  Value<String> id,
  Value<String> opType,
  Value<String> recordId,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$PendingOpsTableTableFilterComposer
    extends Composer<_$AppDatabase, $PendingOpsTableTable> {
  $$PendingOpsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get opType => $composableBuilder(
      column: $table.opType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get recordId => $composableBuilder(
      column: $table.recordId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$PendingOpsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingOpsTableTable> {
  $$PendingOpsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get opType => $composableBuilder(
      column: $table.opType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get recordId => $composableBuilder(
      column: $table.recordId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$PendingOpsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingOpsTableTable> {
  $$PendingOpsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get opType =>
      $composableBuilder(column: $table.opType, builder: (column) => column);

  GeneratedColumn<String> get recordId =>
      $composableBuilder(column: $table.recordId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PendingOpsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PendingOpsTableTable,
    PendingOpsTableData,
    $$PendingOpsTableTableFilterComposer,
    $$PendingOpsTableTableOrderingComposer,
    $$PendingOpsTableTableAnnotationComposer,
    $$PendingOpsTableTableCreateCompanionBuilder,
    $$PendingOpsTableTableUpdateCompanionBuilder,
    (
      PendingOpsTableData,
      BaseReferences<_$AppDatabase, $PendingOpsTableTable, PendingOpsTableData>
    ),
    PendingOpsTableData,
    PrefetchHooks Function()> {
  $$PendingOpsTableTableTableManager(
      _$AppDatabase db, $PendingOpsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingOpsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingOpsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingOpsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> opType = const Value.absent(),
            Value<String> recordId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PendingOpsTableCompanion(
            id: id,
            opType: opType,
            recordId: recordId,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String opType,
            required String recordId,
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              PendingOpsTableCompanion.insert(
            id: id,
            opType: opType,
            recordId: recordId,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PendingOpsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PendingOpsTableTable,
    PendingOpsTableData,
    $$PendingOpsTableTableFilterComposer,
    $$PendingOpsTableTableOrderingComposer,
    $$PendingOpsTableTableAnnotationComposer,
    $$PendingOpsTableTableCreateCompanionBuilder,
    $$PendingOpsTableTableUpdateCompanionBuilder,
    (
      PendingOpsTableData,
      BaseReferences<_$AppDatabase, $PendingOpsTableTable, PendingOpsTableData>
    ),
    PendingOpsTableData,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CategoriesTableTableTableManager get categoriesTable =>
      $$CategoriesTableTableTableManager(_db, _db.categoriesTable);
  $$NotesTableTableTableManager get notesTable =>
      $$NotesTableTableTableManager(_db, _db.notesTable);
  $$ChecklistItemsTableTableTableManager get checklistItemsTable =>
      $$ChecklistItemsTableTableTableManager(_db, _db.checklistItemsTable);
  $$AiSearchHistoryTableTableTableManager get aiSearchHistoryTable =>
      $$AiSearchHistoryTableTableTableManager(_db, _db.aiSearchHistoryTable);
  $$AiCacheTableTableTableManager get aiCacheTable =>
      $$AiCacheTableTableTableManager(_db, _db.aiCacheTable);
  $$PendingOpsTableTableTableManager get pendingOpsTable =>
      $$PendingOpsTableTableTableManager(_db, _db.pendingOpsTable);
}
