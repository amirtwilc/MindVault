import 'package:flutter_test/flutter_test.dart';
import 'package:mindvault/data/models/category_model.dart';
import 'package:mindvault/domain/entities/category.dart';

void main() {
  const iso = '2024-06-15T10:30:00.000Z';

  final json = <String, dynamic>{
    'id': 'cat-1',
    'user_id': 'user-1',
    'name': 'Work',
    'sort_order': 0,
    'last_used_at': iso,
    'created_at': iso,
    'color': '#EF5350',
  };

  group('CategoryModel.fromJson', () {
    test('parses all fields', () {
      final model = CategoryModel.fromJson(json);
      expect(model.id, equals('cat-1'));
      expect(model.userId, equals('user-1'));
      expect(model.name, equals('Work'));
      expect(model.sortOrder, equals(0));
      expect(model.color, equals('#EF5350'));
    });

    test('color is nullable — null when absent', () {
      final noColor = Map<String, dynamic>.from(json)..remove('color');
      final model = CategoryModel.fromJson(noColor);
      expect(model.color, isNull);
    });
  });

  group('CategoryModel.toEntity', () {
    test('converts to Category entity', () {
      final entity = CategoryModel.fromJson(json).toEntity();
      expect(entity, isA<Category>());
      expect(entity.id, equals('cat-1'));
      expect(entity.name, equals('Work'));
      expect(entity.color, equals('#EF5350'));
    });

    test('DateTimes are parsed from ISO strings', () {
      final entity = CategoryModel.fromJson(json).toEntity();
      expect(entity.createdAt, equals(DateTime.parse(iso)));
      expect(entity.lastUsedAt, equals(DateTime.parse(iso)));
    });

    test('null color is preserved in entity', () {
      final noColor = Map<String, dynamic>.from(json)..remove('color');
      final entity = CategoryModel.fromJson(noColor).toEntity();
      expect(entity.color, isNull);
    });
  });
}
