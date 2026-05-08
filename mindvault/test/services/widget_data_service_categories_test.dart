import 'package:flutter_test/flutter_test.dart';
import 'package:mindvault/domain/entities/category.dart';
import 'package:mindvault/domain/entities/note.dart';
import 'package:mindvault/services/widget_data_service.dart';

Category _cat(String id, String name, {int sortOrder = 0, String? color}) =>
    Category(
      id: id,
      userId: 'u1',
      name: name,
      sortOrder: sortOrder,
      color: color,
      lastUsedAt: DateTime(2024),
      createdAt: DateTime(2024),
    );

Note _note(String id, String categoryId) => Note(
      id: id,
      userId: 'u1',
      categoryId: categoryId,
      title: id,
      body: '',
      isPrivate: false,
      isPinned: false,
      pinOrder: null,
      lastUsedAt: DateTime(2024),
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
      lastOpenedAt: null,
    );

void main() {
  group('WidgetDataService.buildPayload — categories', () {
    test('emits a categories array', () {
      final cats = [_cat('c1', 'Work'), _cat('c2', 'Personal')];
      final payload =
          WidgetDataService.buildPayload(categories: cats, allNotes: []);
      expect(payload['categories'], isA<List>());
    });

    test('preserves the input order (categoriesProvider gives sortOrder ASC)',
        () {
      final cats = [
        _cat('c1', 'Work', sortOrder: 0),
        _cat('c2', 'Personal', sortOrder: 1),
        _cat('c3', 'Books', sortOrder: 2),
      ];
      final payload =
          WidgetDataService.buildPayload(categories: cats, allNotes: []);
      final list = payload['categories'] as List;
      expect(list.map((e) => e['id']).toList(), ['c1', 'c2', 'c3']);
    });

    test('each entry has id, name, color, note_count', () {
      final cats = [_cat('c1', 'Work', color: '#FF0000')];
      final payload =
          WidgetDataService.buildPayload(categories: cats, allNotes: []);
      final entry = (payload['categories'] as List).first as Map;
      expect(entry['id'], 'c1');
      expect(entry['name'], 'Work');
      expect(entry['color'], '#FF0000');
      expect(entry['note_count'], 0);
    });

    test('note_count is computed across the full notes list (not just top 20)',
        () {
      final cats = [_cat('c1', 'Work'), _cat('c2', 'Personal')];
      // 25 notes in c1, 3 in c2 — buildPayload caps the visible notes list at
      // 20 but counts must reflect all 28 inputs.
      final notes = [
        ...List.generate(25, (i) => _note('w$i', 'c1')),
        ...List.generate(3, (i) => _note('p$i', 'c2')),
      ];
      final payload =
          WidgetDataService.buildPayload(categories: cats, allNotes: notes);
      final list = payload['categories'] as List;
      expect(list.firstWhere((e) => e['id'] == 'c1')['note_count'], 25);
      expect(list.firstWhere((e) => e['id'] == 'c2')['note_count'], 3);
    });

    test('null color round-trips as null', () {
      final cats = [_cat('c1', 'Work', color: null)];
      final payload =
          WidgetDataService.buildPayload(categories: cats, allNotes: []);
      final entry = (payload['categories'] as List).first as Map;
      expect(entry['color'], isNull);
    });

    test('empty categories yields empty array, not missing key', () {
      final payload =
          WidgetDataService.buildPayload(categories: [], allNotes: []);
      expect(payload['categories'], isA<List>());
      expect((payload['categories'] as List).isEmpty, isTrue);
    });
  });

  group('WidgetDataService.applyNewNote — category counts', () {
    test('increments note_count for the note\'s category', () {
      final current = <String, dynamic>{
        'notes': <Map<String, dynamic>>[],
        'categories': [
          {'id': 'c1', 'name': 'Work', 'color': null, 'note_count': 4},
          {'id': 'c2', 'name': 'Personal', 'color': null, 'note_count': 1},
        ],
      };
      final result = WidgetDataService.applyNewNote(
        current,
        _note('n1', 'c1'),
        [_cat('c1', 'Work'), _cat('c2', 'Personal')],
      );
      final cats = result['categories'] as List;
      expect(cats.firstWhere((e) => e['id'] == 'c1')['note_count'], 5);
      expect(cats.firstWhere((e) => e['id'] == 'c2')['note_count'], 1);
    });

    test('leaves categories unchanged when key is absent', () {
      final current = <String, dynamic>{'notes': <Map<String, dynamic>>[]};
      final result = WidgetDataService.applyNewNote(
        current,
        _note('n1', 'c1'),
        [_cat('c1', 'Work')],
      );
      // No categories key → patch doesn't fabricate one (full sync will).
      expect(result.containsKey('categories'), isFalse);
    });
  });

  group('WidgetDataService.applyUpsertNote — category counts', () {
    test('moves count between categories when categoryId changed', () {
      final current = <String, dynamic>{
        'notes': [
          {
            'id': 'n1',
            'title': 'T',
            'is_pinned': false,
            'category_id': 'c1',
            'category_name': 'Work',
          },
        ],
        'categories': [
          {'id': 'c1', 'name': 'Work', 'color': null, 'note_count': 3},
          {'id': 'c2', 'name': 'Personal', 'color': null, 'note_count': 2},
        ],
      };
      final moved = _note('n1', 'c2');
      final result = WidgetDataService.applyUpsertNote(
        current,
        moved,
        [_cat('c1', 'Work'), _cat('c2', 'Personal')],
      );
      final cats = result['categories'] as List;
      expect(cats.firstWhere((e) => e['id'] == 'c1')['note_count'], 2);
      expect(cats.firstWhere((e) => e['id'] == 'c2')['note_count'], 3);
    });

    test('does not adjust counts when the note was not in the list', () {
      // Note pre-existed outside the top-20 window; we can't infer its prior
      // category, so counts must be left alone (next full sync corrects it).
      final current = <String, dynamic>{
        'notes': <Map<String, dynamic>>[],
        'categories': [
          {'id': 'c1', 'name': 'Work', 'color': null, 'note_count': 10},
        ],
      };
      final result = WidgetDataService.applyUpsertNote(
        current,
        _note('outside', 'c1'),
        [_cat('c1', 'Work')],
      );
      final cats = result['categories'] as List;
      expect(cats.firstWhere((e) => e['id'] == 'c1')['note_count'], 10);
    });
  });
}
