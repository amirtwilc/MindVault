import 'package:flutter_test/flutter_test.dart';
import 'package:mindvault/data/models/note_model.dart';
import 'package:mindvault/domain/entities/note.dart';

void main() {
  const iso = '2024-06-15T10:30:00.000Z';
  final dt = DateTime.parse(iso);

  final json = <String, dynamic>{
    'id': 'note-1',
    'user_id': 'user-1',
    'category_id': 'cat-1',
    'title': 'Test Title',
    'body': 'Test Body',
    'is_private': false,
    'last_used_at': iso,
    'created_at': iso,
    'updated_at': iso,
  };

  group('NoteModel.fromJson', () {
    test('parses all fields correctly', () {
      final model = NoteModel.fromJson(json);
      expect(model.id, equals('note-1'));
      expect(model.userId, equals('user-1'));
      expect(model.categoryId, equals('cat-1'));
      expect(model.title, equals('Test Title'));
      expect(model.body, equals('Test Body'));
      expect(model.isPrivate, isFalse);
      expect(model.lastUsedAt, equals(iso));
      expect(model.createdAt, equals(iso));
      expect(model.updatedAt, equals(iso));
    });

    test('parses isPrivate = true', () {
      final m = NoteModel.fromJson({...json, 'is_private': true});
      expect(m.isPrivate, isTrue);
    });
  });

  group('NoteModel.toEntity', () {
    test('converts to Note entity with parsed DateTimes', () {
      final model = NoteModel.fromJson(json);
      final entity = model.toEntity();
      expect(entity, isA<Note>());
      expect(entity.id, equals('note-1'));
      expect(entity.createdAt, equals(dt));
      expect(entity.updatedAt, equals(dt));
      expect(entity.lastUsedAt, equals(dt));
    });
  });

  group('NoteModel.fromEntity', () {
    test('round-trips through entity without data loss', () {
      final original = NoteModel.fromJson(json);
      final entity = original.toEntity();
      final restored = NoteModel.fromEntity(entity);

      expect(restored.id, equals(original.id));
      expect(restored.title, equals(original.title));
      expect(restored.body, equals(original.body));
      expect(restored.isPrivate, equals(original.isPrivate));
    });

    test('DateTime fields serialize to ISO-8601 strings', () {
      final entity = NoteModel.fromJson(json).toEntity();
      final model = NoteModel.fromEntity(entity);
      // Must be parseable back to DateTime
      expect(() => DateTime.parse(model.createdAt), returnsNormally);
      expect(() => DateTime.parse(model.updatedAt), returnsNormally);
    });
  });
}
