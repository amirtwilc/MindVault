import 'package:flutter_test/flutter_test.dart';
import 'package:mindvault/domain/entities/category.dart';
import 'package:mindvault/domain/entities/note.dart';
import 'package:mindvault/services/widget_data_service.dart';

Category _cat(String id, String name) => Category(
      id: id,
      userId: 'u1',
      name: name,
      sortOrder: 0,
      color: null,
      lastUsedAt: DateTime(2024),
      createdAt: DateTime(2024),
    );

Note _note(String id, String title,
        {required String categoryId,
        bool isPrivate = false,
        bool isPinned = false,
        int? pinOrder,
        DateTime? createdAt,
        DateTime? lastOpenedAt}) =>
    Note(
      id: id,
      userId: 'u1',
      categoryId: categoryId,
      title: title,
      body: '',
      isPrivate: isPrivate,
      isPinned: isPinned,
      pinOrder: pinOrder,
      lastUsedAt: DateTime(2024),
      createdAt: createdAt ?? DateTime(2024),
      updatedAt: DateTime(2024),
      lastOpenedAt: lastOpenedAt,
    );

void main() {
  final cats = [_cat('c1', 'Work'), _cat('c2', 'Personal')];

  group('WidgetDataService.buildPayload', () {
    test('includes private notes with actual title', () {
      final notes = [
        _note('n1', 'Public', categoryId: 'c1'),
        _note('n2', 'Secret', categoryId: 'c1', isPrivate: true),
      ];
      final payload =
          WidgetDataService.buildPayload(categories: cats, allNotes: notes);
      final list = payload['notes'] as List;
      expect(list.length, 2);

      final secret = list.firstWhere((e) => e['id'] == 'n2') as Map;
      expect(secret['is_private'], true);
      expect(secret['title'], 'Secret');

      final public = list.firstWhere((e) => e['id'] == 'n1') as Map;
      expect(public['is_private'], false);
      expect(public['title'], 'Public');
    });

    test('sorted by most recently touched (lastOpenedAt beats createdAt)', () {
      final notes = [
        _note('n1', 'A', categoryId: 'c1', createdAt: DateTime(2024, 1, 1)),
        _note('n2', 'B', categoryId: 'c1',
            createdAt: DateTime(2024, 1, 2),
            lastOpenedAt: DateTime(2024, 6, 1)),
        _note('n3', 'C', categoryId: 'c1',
            createdAt: DateTime(2024, 1, 3)),
      ];
      final payload =
          WidgetDataService.buildPayload(categories: cats, allNotes: notes);
      final list = payload['notes'] as List;
      expect(list[0]['id'], 'n2'); // opened most recently
      expect(list[1]['id'], 'n3'); // created most recently
      expect(list[2]['id'], 'n1');
    });

    test('capped at 20 notes', () {
      final notes = List.generate(
        25,
        (i) => _note('n$i', 'Note $i',
            categoryId: 'c1',
            createdAt: DateTime(2024, 1, i + 1)),
      );
      final payload =
          WidgetDataService.buildPayload(categories: cats, allNotes: notes);
      expect((payload['notes'] as List).length, 20);
    });

    test('each entry has id, title, category_id, category_name', () {
      final notes = [_note('n1', 'Alpha', categoryId: 'c2')];
      final payload =
          WidgetDataService.buildPayload(categories: cats, allNotes: notes);
      final entry = (payload['notes'] as List).first as Map;
      expect(entry['id'], 'n1');
      expect(entry['title'], 'Alpha');
      expect(entry['category_id'], 'c2');
      expect(entry['category_name'], 'Personal');
    });

    test('empty lists produce empty notes array', () {
      final payload =
          WidgetDataService.buildPayload(categories: [], allNotes: []);
      expect((payload['notes'] as List).isEmpty, isTrue);
      expect(payload['recent_category_id'], '');
    });

    test('recent_category_id from most recently touched note', () {
      final notes = [_note('n1', 'Hello', categoryId: 'c2')];
      final payload =
          WidgetDataService.buildPayload(categories: cats, allNotes: notes);
      expect(payload['recent_category_id'], 'c2');
    });
  });

  group('WidgetDataService.applyNewNote', () {
    test('prepends note to notes list', () {
      final current = <String, dynamic>{'notes': []};
      final note = _note('n1', 'My note', categoryId: 'c1');
      final result = WidgetDataService.applyNewNote(current, note, cats);
      final list = result['notes'] as List;
      expect(list.first['id'], 'n1');
      expect(list.first['title'], 'My note');
    });

    test('caps notes at 20', () {
      final existing = List.generate(
        20,
        (i) => {'id': 'e$i', 'title': 'E$i', 'category_id': 'c1', 'category_name': 'Work'},
      );
      final current = <String, dynamic>{'notes': existing};
      final result = WidgetDataService.applyNewNote(
          current, _note('new', 'New', categoryId: 'c1'), cats);
      final list = result['notes'] as List;
      expect(list.length, 20);
      expect(list.first['id'], 'new');
    });

    test('private note is added with actual title', () {
      final current = <String, dynamic>{'notes': []};
      final note = _note('n1', 'Secret', categoryId: 'c1', isPrivate: true);
      final result = WidgetDataService.applyNewNote(current, note, cats);
      final list = result['notes'] as List;
      expect(list.length, 1);
      expect(list.first['id'], 'n1');
      expect(list.first['is_private'], true);
      expect(list.first['title'], 'Secret');
    });

    test('entry includes category_name', () {
      final result = WidgetDataService.applyNewNote(
          {}, _note('n1', 'T', categoryId: 'c2'), cats);
      final entry = (result['notes'] as List).first as Map;
      expect(entry['category_name'], 'Personal');
    });

    test('updates recent_category_id', () {
      final result = WidgetDataService.applyNewNote(
          {}, _note('n1', 'T', categoryId: 'c2'), cats);
      expect(result['recent_category_id'], 'c2');
    });

    test('preserves other fields in current data', () {
      final current = {'custom_field': 'keep', 'notes': []};
      final result = WidgetDataService.applyNewNote(
          current, _note('n1', 'T', categoryId: 'c1'), cats);
      expect(result['custom_field'], 'keep');
    });

    test('defaults to empty notes when missing from current', () {
      final result =
          WidgetDataService.applyNewNote({}, _note('n1', 'T', categoryId: 'c1'), cats);
      expect((result['notes'] as List).first['id'], 'n1');
    });
  });

  group('WidgetDataService.applyNoteOpened', () {
    test('promotes note to top of list', () {
      final existing = [
        {'id': 'a', 'title': 'A', 'category_id': 'c1', 'category_name': 'Work'},
        {'id': 'b', 'title': 'B', 'category_id': 'c1', 'category_name': 'Work'},
      ];
      final current = <String, dynamic>{'notes': existing};
      final note = _note('b', 'B', categoryId: 'c1');
      final result = WidgetDataService.applyNoteOpened(current, note, cats);
      final list = result['notes'] as List;
      expect(list.first['id'], 'b');
      expect(list[1]['id'], 'a');
    });

    test('private note is promoted with actual title', () {
      final existing = [
        {'id': 'a', 'title': 'A', 'category_id': 'c1', 'category_name': 'Work'},
      ];
      final current = <String, dynamic>{'notes': existing};
      final note = _note('n1', 'Secret', categoryId: 'c1', isPrivate: true);
      final result = WidgetDataService.applyNoteOpened(current, note, cats);
      final list = result['notes'] as List;
      expect(list.first['id'], 'n1');
      expect(list.first['is_private'], true);
      expect(list.first['title'], 'Secret');
    });
  });

  group('WidgetDataService.buildPayload — pinned ordering', () {
    test('pinned notes appear before unpinned notes', () {
      final notes = [
        _note('u1', 'Unpinned', categoryId: 'c1',
            createdAt: DateTime(2024, 6, 1)),
        _note('p1', 'Pinned', categoryId: 'c1',
            isPinned: true, pinOrder: 0, createdAt: DateTime(2024, 1, 1)),
      ];
      final payload =
          WidgetDataService.buildPayload(categories: cats, allNotes: notes);
      final list = payload['notes'] as List;
      expect(list.first['id'], 'p1');
      expect(list.last['id'], 'u1');
    });

    test('pinned notes are ordered by pinOrder ASC', () {
      final notes = [
        _note('p2', 'Second', categoryId: 'c1', isPinned: true, pinOrder: 1),
        _note('p1', 'First', categoryId: 'c1', isPinned: true, pinOrder: 0),
        _note('u1', 'Unpinned', categoryId: 'c1'),
      ];
      final payload =
          WidgetDataService.buildPayload(categories: cats, allNotes: notes);
      final list = payload['notes'] as List;
      expect(list[0]['id'], 'p1');
      expect(list[1]['id'], 'p2');
      expect(list[2]['id'], 'u1');
    });

    test('note entries include is_pinned field', () {
      final notes = [
        _note('p1', 'Pinned', categoryId: 'c1', isPinned: true, pinOrder: 0),
        _note('u1', 'Unpinned', categoryId: 'c1'),
      ];
      final payload =
          WidgetDataService.buildPayload(categories: cats, allNotes: notes);
      final list = payload['notes'] as List;
      expect((list[0] as Map)['is_pinned'], isTrue);
      expect((list[1] as Map)['is_pinned'], isFalse);
    });
  });

  group('WidgetDataService.applyNewNote — pinned section', () {
    test('new unpinned note lands after pinned notes', () {
      final existing = [
        {'id': 'p1', 'title': 'Pinned', 'is_pinned': true, 'category_id': 'c1', 'category_name': 'Work'},
        {'id': 'u1', 'title': 'Unpinned', 'is_pinned': false, 'category_id': 'c1', 'category_name': 'Work'},
      ];
      final current = <String, dynamic>{'notes': existing};
      final newNote = _note('u2', 'New Unpinned', categoryId: 'c1');
      final result = WidgetDataService.applyNewNote(current, newNote, cats);
      final list = result['notes'] as List;
      expect(list[0]['id'], 'p1');  // pinned stays first
      expect(list[1]['id'], 'u2');  // new unpinned after pinned
      expect(list[2]['id'], 'u1');
    });
  });

  group('WidgetDataService.applyNoteOpened — pinned section', () {
    test('opened unpinned note lands after pinned section', () {
      final existing = [
        {'id': 'p1', 'title': 'Pinned', 'is_pinned': true, 'category_id': 'c1', 'category_name': 'Work'},
        {'id': 'u1', 'title': 'Unpinned1', 'is_pinned': false, 'category_id': 'c1', 'category_name': 'Work'},
        {'id': 'u2', 'title': 'Unpinned2', 'is_pinned': false, 'category_id': 'c1', 'category_name': 'Work'},
      ];
      final current = <String, dynamic>{'notes': existing};
      final opened = _note('u2', 'Unpinned2', categoryId: 'c1');
      final result = WidgetDataService.applyNoteOpened(current, opened, cats);
      final list = result['notes'] as List;
      expect(list[0]['id'], 'p1');  // pinned stays first
      expect(list[1]['id'], 'u2');  // opened unpinned after pinned
      expect(list[2]['id'], 'u1');
    });

    test('opened pinned note updates in place, preserving pinOrder position', () {
      final existing = [
        {'id': 'p1', 'title': 'P1', 'is_pinned': true, 'category_id': 'c1', 'category_name': 'Work'},
        {'id': 'p2', 'title': 'P2', 'is_pinned': true, 'category_id': 'c1', 'category_name': 'Work'},
        {'id': 'u1', 'title': 'U1', 'is_pinned': false, 'category_id': 'c1', 'category_name': 'Work'},
      ];
      final current = <String, dynamic>{'notes': existing};
      final opened = _note('p2', 'P2 updated', categoryId: 'c1', isPinned: true);
      final result = WidgetDataService.applyNoteOpened(current, opened, cats);
      final list = result['notes'] as List;
      // Pinned notes must not be reordered by recency — position governed by pinOrder.
      expect(list[0]['id'], 'p1');
      expect(list[1]['id'], 'p2');
      expect(list[1]['title'], 'P2 updated'); // entry data refreshed
      expect(list[2]['id'], 'u1');
    });
  });

  group('WidgetDataService.applyUpsertNote', () {
    test('updates existing entry in place without reordering', () {
      final existing = [
        {'id': 'a', 'title': 'A', 'is_private': true, 'category_id': 'c1', 'category_name': 'Work'},
        {'id': 'b', 'title': 'B', 'is_private': false, 'category_id': 'c1', 'category_name': 'Work'},
      ];
      final current = <String, dynamic>{'notes': existing};
      // Note "a" was just unlocked in the main app — flip to public.
      final unlocked = _note('a', 'A', categoryId: 'c1', isPrivate: false);
      final result = WidgetDataService.applyUpsertNote(current, unlocked, cats);
      final list = result['notes'] as List;
      // Order preserved.
      expect(list[0]['id'], 'a');
      expect(list[1]['id'], 'b');
      // is_private flipped on the upserted entry.
      expect(list[0]['is_private'], false);
    });

    test('inserts at top when entry is missing', () {
      final existing = [
        {'id': 'a', 'title': 'A', 'category_id': 'c1', 'category_name': 'Work'},
      ];
      final current = <String, dynamic>{'notes': existing};
      final fresh = _note('z', 'New from editor', categoryId: 'c2');
      final result = WidgetDataService.applyUpsertNote(current, fresh, cats);
      final list = result['notes'] as List;
      expect(list.first['id'], 'z');
      expect(list[1]['id'], 'a');
    });

    test('caps notes at 20 when inserting a new entry', () {
      final existing = List.generate(
        20,
        (i) => {'id': 'e$i', 'title': 'E$i', 'category_id': 'c1', 'category_name': 'Work'},
      );
      final current = <String, dynamic>{'notes': existing};
      final result = WidgetDataService.applyUpsertNote(
          current, _note('new', 'New', categoryId: 'c1'), cats);
      final list = result['notes'] as List;
      expect(list.length, 20);
      expect(list.first['id'], 'new');
    });

    test('preserves other top-level fields', () {
      final current = {
        'custom': 'keep',
        'recent_category_id': 'c2',
        'notes': <Map<String, dynamic>>[],
      };
      final result = WidgetDataService.applyUpsertNote(
          current, _note('n', 'T', categoryId: 'c1'), cats);
      expect(result['custom'], 'keep');
      expect(result['recent_category_id'], 'c2');
    });
  });
}
