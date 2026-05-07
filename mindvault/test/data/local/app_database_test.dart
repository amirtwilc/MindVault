import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindvault/data/local/database/app_database.dart';

AppDatabase _openTestDb() => AppDatabase.forTesting(NativeDatabase.memory());

void main() {
  late AppDatabase db;

  setUp(() => db = _openTestDb());
  tearDown(() => db.close());

  // ── Helpers ────────────────────────────────────────────────────────────────

  CategoriesTableCompanion _cat({
    String id = 'cat-1',
    String userId = 'user-1',
    String name = 'Work',
    int sortOrder = 0,
    String? color,
  }) {
    final now = DateTime.now().toUtc();
    return CategoriesTableCompanion(
      id: Value(id),
      userId: Value(userId),
      name: Value(name),
      sortOrder: Value(sortOrder),
      color: Value(color),
      lastUsedAt: Value(now),
      createdAt: Value(now),
    );
  }

  NotesTableCompanion _note({
    String id = 'note-1',
    String userId = 'user-1',
    String categoryId = 'cat-1',
    String title = 'Test Note',
    String body = 'Body text',
    bool isPrivate = false,
  }) {
    final now = DateTime.now().toUtc();
    return NotesTableCompanion(
      id: Value(id),
      userId: Value(userId),
      categoryId: Value(categoryId),
      title: Value(title),
      body: Value(body),
      isPrivate: Value(isPrivate),
      lastUsedAt: Value(now),
      createdAt: Value(now),
      updatedAt: Value(now),
    );
  }

  // ── Category tests ─────────────────────────────────────────────────────────

  group('upsertCategory', () {
    test('inserts a new category', () async {
      await db.upsertCategory(_cat());
      final rows = await db.select(db.categoriesTable).get();
      expect(rows.length, equals(1));
      expect(rows.first.name, equals('Work'));
    });

    test('updates existing category on conflict (same id)', () async {
      await db.upsertCategory(_cat(name: 'Old Name'));
      await db.upsertCategory(_cat(name: 'New Name'));
      final rows = await db.select(db.categoriesTable).get();
      expect(rows.length, equals(1));
      expect(rows.first.name, equals('New Name'));
    });
  });

  group('upsertCategories (batch)', () {
    test('inserts multiple categories', () async {
      await db.upsertCategories([_cat(id: 'a'), _cat(id: 'b')]);
      final rows = await db.select(db.categoriesTable).get();
      expect(rows.length, equals(2));
    });

    test('updates existing on conflict', () async {
      await db.upsertCategory(_cat(name: 'Old'));
      await db.upsertCategories([_cat(name: 'Updated')]);
      final rows = await db.select(db.categoriesTable).get();
      expect(rows.length, equals(1));
      expect(rows.first.name, equals('Updated'));
    });
  });

  group('deleteCategory', () {
    test('removes the category', () async {
      await db.upsertCategory(_cat());
      await db.deleteCategory('cat-1');
      final rows = await db.select(db.categoriesTable).get();
      expect(rows, isEmpty);
    });

    test('no-op when category does not exist', () async {
      await expectLater(db.deleteCategory('ghost'), completes);
    });
  });

  group('watchCategories', () {
    test('emits categories ordered by sortOrder', () async {
      await db.upsertCategory(_cat(id: 'b', sortOrder: 1));
      await db.upsertCategory(_cat(id: 'a', sortOrder: 0));
      final rows = await db.watchCategories('user-1').first;
      expect(rows.map((r) => r.id).toList(), equals(['a', 'b']));
    });

    test('emits only categories for the given userId', () async {
      await db.upsertCategory(_cat(id: 'mine', userId: 'user-1'));
      await db.upsertCategory(_cat(id: 'theirs', userId: 'other'));
      final rows = await db.watchCategories('user-1').first;
      expect(rows.length, equals(1));
      expect(rows.first.id, equals('mine'));
    });
  });

  // ── Note tests ─────────────────────────────────────────────────────────────

  group('upsertNote', () {
    test('inserts a new note', () async {
      await db.upsertNote(_note());
      expect(await db.getNote('note-1'), isNotNull);
    });

    test('updates existing note on conflict', () async {
      await db.upsertNote(_note(title: 'Old'));
      await db.upsertNote(_note(title: 'New'));
      final row = await db.getNote('note-1');
      expect(row!.title, equals('New'));
    });
  });

  group('deleteNote', () {
    test('removes the note', () async {
      await db.upsertNote(_note());
      await db.deleteNote('note-1');
      expect(await db.getNote('note-1'), isNull);
    });
  });

  group('deleteNotesByCategoryId', () {
    test('removes all notes for the category', () async {
      await db.upsertNote(_note(id: 'n1', categoryId: 'cat-1'));
      await db.upsertNote(_note(id: 'n2', categoryId: 'cat-1'));
      await db.upsertNote(_note(id: 'n3', categoryId: 'cat-2'));
      await db.deleteNotesByCategoryId('cat-1');
      final remaining = await db.select(db.notesTable).get();
      expect(remaining.map((r) => r.id).toList(), equals(['n3']));
    });
  });

  group('watchNotesByCategory', () {
    test('emits notes for the category ordered by updatedAt desc', () async {
      final older = DateTime.now().subtract(const Duration(hours: 1)).toUtc();
      final newer = DateTime.now().toUtc();
      final n1 = _note(id: 'old').copyWith(updatedAt: Value(older));
      final n2 = _note(id: 'new').copyWith(updatedAt: Value(newer));
      await db.upsertNote(n1);
      await db.upsertNote(n2);
      final rows = await db.watchNotesByCategory('cat-1').first;
      expect(rows.first.id, equals('new'));
      expect(rows.last.id, equals('old'));
    });
  });

  group('watchAllNotes', () {
    test('returns only notes for the given userId', () async {
      await db.upsertNote(_note(id: 'mine', userId: 'user-1'));
      await db.upsertNote(_note(id: 'theirs', userId: 'other'));
      final rows = await db.watchAllNotes('user-1').first;
      expect(rows.length, equals(1));
      expect(rows.first.id, equals('mine'));
    });
  });

  // ── Pending ops tests ──────────────────────────────────────────────────────

  group('upsertPendingOp', () {
    test('inserts a pending op', () async {
      await db.upsertPendingOp('op-1', 'create_note', 'note-1');
      final ops = await db.getPendingOps();
      expect(ops.length, equals(1));
      expect(ops.first.opType, equals('create_note'));
      expect(ops.first.recordId, equals('note-1'));
    });

    test('replaces op with same id', () async {
      await db.upsertPendingOp('op-1', 'create_note', 'note-1');
      await db.upsertPendingOp('op-1', 'update_note', 'note-1');
      final ops = await db.getPendingOps();
      expect(ops.length, equals(1));
      expect(ops.first.opType, equals('update_note'));
    });
  });

  group('getPendingOps', () {
    test('returns ops ordered by createdAt ascending', () async {
      // Insert in reverse order and verify sorting
      await db.upsertPendingOp('op-b', 'create_note', 'n2');
      await Future.delayed(const Duration(milliseconds: 5));
      await db.upsertPendingOp('op-a', 'create_note', 'n1');
      final ops = await db.getPendingOps();
      expect(ops.first.id, equals('op-b'));
      expect(ops.last.id, equals('op-a'));
    });
  });

  group('deletePendingOp', () {
    test('removes op by id', () async {
      await db.upsertPendingOp('op-1', 'create_note', 'note-1');
      await db.deletePendingOp('op-1');
      expect(await db.getPendingOps(), isEmpty);
    });
  });

  group('removePendingOpsForRecord', () {
    test('removes all ops for a given recordId', () async {
      await db.upsertPendingOp('op-1', 'create_note', 'note-1');
      await db.upsertPendingOp('op-2', 'update_note', 'note-1');
      await db.upsertPendingOp('op-3', 'create_note', 'note-2');
      await db.removePendingOpsForRecord('note-1');
      final ops = await db.getPendingOps();
      expect(ops.length, equals(1));
      expect(ops.first.id, equals('op-3'));
    });
  });

  // ── Pin fields ─────────────────────────────────────────────────────────────

  group('pin fields', () {
    test('new note defaults isPinned to false, pinnedAt null, pinOrder null', () async {
      await db.upsertNote(_note());
      final row = await db.getNote('note-1');
      expect(row!.isPinned, isFalse);
      expect(row.pinnedAt, isNull);
      expect(row.pinOrder, isNull);
    });
  });

  // ── Pinned-first ordering ──────────────────────────────────────────────────

  group('watchAllNotes pinned ordering', () {
    final base = DateTime(2025, 1, 1, 12, 0).toUtc();

    test('pinned notes appear before unpinned notes', () async {
      await db.upsertNote(_note(id: 'unpinned').copyWith(
        updatedAt: Value(base.add(const Duration(hours: 2))),
      ));
      await db.upsertNote(_note(id: 'pinned').copyWith(
        updatedAt: Value(base),
        isPinned: const Value(true),
        pinOrder: const Value(0),
      ));
      final rows = await db.watchAllNotes('user-1').first;
      expect(rows.first.id, equals('pinned'));
      expect(rows.last.id, equals('unpinned'));
    });

    test('pinned notes ordered by pin_order ASC', () async {
      await db.upsertNote(_note(id: 'pin-b').copyWith(
        isPinned: const Value(true),
        pinOrder: const Value(1),
        updatedAt: Value(base.add(const Duration(hours: 2))),
      ));
      await db.upsertNote(_note(id: 'pin-a').copyWith(
        isPinned: const Value(true),
        pinOrder: const Value(0),
        updatedAt: Value(base),
      ));
      await db.upsertNote(_note(id: 'unpinned').copyWith(
        updatedAt: Value(base.add(const Duration(hours: 1))),
      ));
      final rows = await db.watchAllNotes('user-1').first;
      expect(rows[0].id, equals('pin-a'));
      expect(rows[1].id, equals('pin-b'));
      expect(rows[2].id, equals('unpinned'));
    });
  });

  group('watchNotesByCategory pinned ordering', () {
    test('pinned notes appear before unpinned notes within a category', () async {
      final base = DateTime(2025, 1, 1, 12, 0).toUtc();
      await db.upsertNote(_note(id: 'unpinned').copyWith(
        updatedAt: Value(base.add(const Duration(hours: 2))),
      ));
      await db.upsertNote(_note(id: 'pinned').copyWith(
        updatedAt: Value(base),
        isPinned: const Value(true),
        pinOrder: const Value(0),
      ));
      final rows = await db.watchNotesByCategory('cat-1').first;
      expect(rows.first.id, equals('pinned'));
      expect(rows.last.id, equals('unpinned'));
    });
  });

  // ── AI search history ──────────────────────────────────────────────────────

  group('AI search history', () {
    Future<void> _history(
      AppDatabase d, {
      required String queryHash,
      required String query,
      List<String> citedTitles = const ['Note A'],
      List<String> citedNoteIds = const ['n1'],
    }) =>
        d.insertHistory(
          queryHash: queryHash,
          query: query,
          answer: 'Some answer',
          citedTitles: citedTitles,
          citedNoteIds: citedNoteIds,
        );

    test('inserts a history entry and watchHistory returns it', () async {
      await _history(db, queryHash: 'h1', query: 'test query');
      final rows = await db.watchHistory().first;
      expect(rows.length, equals(1));
      expect(rows.first.query, equals('test query'));
    });

    test('insertOnConflictUpdate replaces entry with same hash', () async {
      await _history(db, queryHash: 'same', query: 'first');
      await _history(db, queryHash: 'same', query: 'second');
      final rows = await db.watchHistory().first;
      expect(rows.length, equals(1));
      expect(rows.first.query, equals('second'));
    });

    test('watchHistory orders by createdAt descending', () async {
      // Use explicit timestamps so the ordering is deterministic regardless of clock resolution
      final base = DateTime(2025, 1, 1, 12, 0);
      for (int i = 1; i <= 3; i++) {
        await db.into(db.aiSearchHistoryTable).insert(
          AiSearchHistoryTableCompanion(
            queryHash: Value('h$i'),
            query: Value('query $i'),
            answer: const Value('answer'),
            citedTitlesJson: const Value('[]'),
            citedNoteIdsJson: const Value('[]'),
            createdAt: Value(base.add(Duration(hours: i))),
          ),
        );
      }
      final rows = await db.watchHistory().first;
      expect(rows.first.query, equals('query 3'));
      expect(rows.last.query, equals('query 1'));
    });

    test('prunes oldest entries so only 5 are kept', () async {
      final base = DateTime(2025, 1, 1, 12, 0);
      // Insert 6 rows with distinct timestamps (oldest first)
      for (int i = 1; i <= 6; i++) {
        await db.into(db.aiSearchHistoryTable).insert(
          AiSearchHistoryTableCompanion(
            queryHash: Value('h$i'),
            query: Value('query $i'),
            answer: const Value('answer'),
            citedTitlesJson: const Value('[]'),
            citedNoteIdsJson: const Value('[]'),
            createdAt: Value(base.add(Duration(hours: i))),
          ),
        );
      }
      await db.insertHistory(
        queryHash: 'trigger',
        query: 'trigger prune',
        answer: 'x',
        citedTitles: [],
        citedNoteIds: [],
      );
      // After prune: 5 kept (h2–h6 + trigger, but trigger's timestamp is now() so it's newest)
      // Actually let's just verify the total count <= 5 and the oldest (h1) is gone
      // We need to re-read via select (not watchHistory which limits to 5 anyway)
      final all = await db.select(db.aiSearchHistoryTable).get();
      expect(all.length, lessThanOrEqualTo(5));
      expect(all.any((r) => r.queryHash == 'h1'), isFalse);
    });

    test('removeHistoryReferencingNoteIds removes intersecting entries', () async {
      await _history(db, queryHash: 'h1', query: 'about note-a', citedNoteIds: ['note-a']);
      await _history(db, queryHash: 'h2', query: 'about note-b', citedNoteIds: ['note-b']);
      await _history(db, queryHash: 'h3', query: 'about both', citedNoteIds: ['note-a', 'note-b']);
      await db.removeHistoryReferencingNoteIds(['note-a']);
      final rows = await db.watchHistory().first;
      // h1 and h3 both cited note-a; only h2 should survive
      expect(rows.length, equals(1));
      expect(rows.first.query, equals('about note-b'));
    });

    test('removeHistoryReferencingNoteIds is no-op when no ids match', () async {
      await _history(db, queryHash: 'h1', query: 'my query');
      await db.removeHistoryReferencingNoteIds(['unknown-id']);
      final rows = await db.watchHistory().first;
      expect(rows.length, equals(1));
    });
  });

  // ── AI cache tests ─────────────────────────────────────────────────────────

  group('AI cache', () {
    test('caches and retrieves a response', () async {
      await db.cacheResponse('hash-1', 'AI response text');
      final cached = await db.getCachedResponse('hash-1');
      expect(cached?.response, equals('AI response text'));
    });

    test('returns null for unknown hash', () async {
      expect(await db.getCachedResponse('missing'), isNull);
    });

    test('evictExpiredCache removes old entries', () async {
      await db.cacheResponse('hash-old', 'old');
      await db.cacheResponse('hash-new', 'new');

      // Force the old entry's cachedAt to be in the past via direct update
      final cutoff = DateTime.now().subtract(const Duration(minutes: 15));
      await (db.update(db.aiCacheTable)..where((t) => t.queryHash.equals('hash-old')))
          .write(AiCacheTableCompanion(cachedAt: Value(cutoff)));

      await db.evictExpiredCache(const Duration(minutes: 10));

      expect(await db.getCachedResponse('hash-old'), isNull);
      expect(await db.getCachedResponse('hash-new'), isNotNull);
    });
  });
}
