import 'package:flutter_test/flutter_test.dart';
import 'package:mindvault/domain/entities/category.dart';
import 'package:mindvault/domain/entities/note.dart';
import 'package:mindvault/presentation/providers/search_provider.dart';

void main() {
  final base = DateTime(2025, 1, 1, 12, 0);

  Note makeNote({
    String id = 'n1',
    String title = 'Test Note',
    String body = '',
    bool isPrivate = false,
    String categoryId = 'c1',
    bool isPinned = false,
    DateTime? lastOpenedAt,
    DateTime? createdAt,
  }) =>
      Note(
        id: id,
        userId: 'u1',
        categoryId: categoryId,
        title: title,
        body: body,
        isPrivate: isPrivate,
        isPinned: isPinned,
        lastUsedAt: base,
        createdAt: createdAt ?? base,
        updatedAt: base,
        lastOpenedAt: lastOpenedAt,
      );

  Category makeCategory({String id = 'c1', String name = 'General'}) =>
      Category(
        id: id,
        userId: 'u1',
        name: name,
        sortOrder: 0,
        lastUsedAt: base,
        createdAt: base,
      );

  final catMap = {makeCategory().id: makeCategory()};

  // ── Existing tests (preserved) ────────────────────────────────────────────

  group('filterNotesForSearch – basics', () {
    test('returns empty list for empty query', () {
      final notes = [makeNote(title: 'Hello')];
      expect(filterNotesForSearch('', notes, catMap), isEmpty);
      expect(filterNotesForSearch('   ', notes, catMap), isEmpty);
    });

    test('excludes private notes from results', () {
      final notes = [makeNote(title: 'Secret', isPrivate: true)];
      expect(filterNotesForSearch('secret', notes, catMap), isEmpty);
    });

    test('matches by note title (case-insensitive)', () {
      final notes = [makeNote(title: 'Flutter Tips')];
      final results = filterNotesForSearch('FLUTTER', notes, catMap);
      expect(results, hasLength(1));
      expect(results.first.note.title, 'Flutter Tips');
      expect(results.first.matchingLines, isEmpty);
    });

    test('matches by body line and returns the matching line', () {
      final notes = [makeNote(body: 'first line\nfoo bar baz\nlast line')];
      final results = filterNotesForSearch('foo', notes, catMap);
      expect(results, hasLength(1));
      expect(results.first.matchingLines, ['foo bar baz']);
    });

    test('returns multiple matching lines from one note', () {
      final notes = [
        makeNote(body: 'dart is great\nflutter uses dart\nother line')
      ];
      final results = filterNotesForSearch('dart', notes, catMap);
      expect(results.first.matchingLines, hasLength(2));
    });

    test('attaches the correct category to the result', () {
      final cat = makeCategory(id: 'c2', name: 'Work');
      final notes = [makeNote(categoryId: 'c2', title: 'Meeting notes')];
      final results = filterNotesForSearch('meeting', notes, {cat.id: cat});
      expect(results.first.category?.name, 'Work');
    });

    test('returns null category when category is not in map', () {
      final notes = [makeNote(categoryId: 'unknown', title: 'Orphan note')];
      final results = filterNotesForSearch('orphan', notes, {});
      expect(results.first.category, isNull);
    });

    test('skips blank lines in body', () {
      final notes = [makeNote(body: '\n\n  \nhello world\n  \n')];
      final results = filterNotesForSearch('hello', notes, catMap);
      expect(results.first.matchingLines, ['hello world']);
    });

    test('does not return note when neither title nor body matches', () {
      final notes = [makeNote(title: 'Apples', body: 'Some fruit info')];
      expect(filterNotesForSearch('mango', notes, catMap), isEmpty);
    });
  });

  // ── Scoring tier tests ────────────────────────────────────────────────────

  group('filterNotesForSearch – scoring tiers', () {
    test('exact-phrase title match scores higher than exact-phrase body match',
        () {
      final titleNote =
          makeNote(id: 'a', title: 'banana sandwich', body: 'other');
      final bodyNote =
          makeNote(id: 'b', title: 'other', body: 'banana sandwich');
      final results = filterNotesForSearch(
        'banana sandwich',
        [bodyNote, titleNote],
        catMap,
        now: base,
      );
      expect(results.first.note.id, 'a');
    });

    test('OR-only note is excluded; AND note is included', () {
      final andNote =
          makeNote(id: 'and', title: 'sandwich with banana', body: '');
      final orNote = makeNote(id: 'or', title: 'banana cake', body: '');
      final results = filterNotesForSearch(
        'banana sandwich',
        [orNote, andNote],
        catMap,
        now: base,
      );
      expect(results.first.note.id, 'and');
      expect(results.any((r) => r.note.id == 'or'), isFalse);
    });

    test('"nan" (substring) finds "banana"', () {
      final notes = [makeNote(title: 'banana split')];
      final results = filterNotesForSearch('nan', notes, catMap, now: base);
      expect(results, hasLength(1));
    });

    test('"nan" finds "nano" via substring', () {
      final notes = [makeNote(title: 'nanoparticle')];
      final results = filterNotesForSearch('nan', notes, catMap, now: base);
      expect(results, hasLength(1));
    });

    test('pinned note ranks above unpinned note with same tier-3 hits', () {
      final pinned =
          makeNote(id: 'pinned', title: 'apple note', isPinned: true);
      final unpinned =
          makeNote(id: 'unpinned', title: 'apple info', isPinned: false);
      final results = filterNotesForSearch(
        'apple',
        [unpinned, pinned],
        catMap,
        now: base,
      );
      expect(results.first.note.id, 'pinned');
    });

    test('recently-touched note ranks above stale note with same score', () {
      final fresh = makeNote(
        id: 'fresh',
        title: 'mango note',
        lastOpenedAt: base.subtract(const Duration(days: 3)),
      );
      final stale = makeNote(
        id: 'stale',
        title: 'mango info',
        createdAt: base.subtract(const Duration(days: 60)),
      );
      // Both hit tier-3 substring on 'mango'; fresh gets recency boost
      final results = filterNotesForSearch(
        'mango',
        [stale, fresh],
        catMap,
        now: base,
      );
      expect(results.first.note.id, 'fresh');
    });

    test('private notes are excluded regardless of query match', () {
      final notes = [makeNote(title: 'Secret data', isPrivate: true)];
      expect(filterNotesForSearch('secret', notes, catMap), isEmpty);
    });

    test(
        'multi-token "banana sandwich" matches "sandwich with banana" (AND tier)',
        () {
      final notes = [makeNote(title: 'sandwich with banana')];
      final results =
          filterNotesForSearch('banana sandwich', notes, catMap, now: base);
      expect(results, hasLength(1));
    });

    test('exact-phrase title beat AND title for same query', () {
      final exact = makeNote(id: 'exact', title: 'banana sandwich recipe');
      final andMatch =
          makeNote(id: 'and', title: 'sandwich with banana inside');
      final results = filterNotesForSearch(
        'banana sandwich',
        [andMatch, exact],
        catMap,
        now: base,
      );
      expect(results.first.note.id, 'exact');
    });

    test('score field is set and positive for matches', () {
      final notes = [makeNote(title: 'hello world')];
      final results = filterNotesForSearch('hello', notes, catMap, now: base);
      expect(results.first.score, greaterThan(0));
    });
  });
}
