import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindvault/data/local/database/app_database.dart';
import 'package:mindvault/data/models/checklist_item_model.dart';
import 'package:mindvault/data/models/note_model.dart';
import 'package:mindvault/data/remote/supabase/supabase_notes_datasource.dart';
import 'package:mindvault/data/repositories/note_repository_impl.dart';
import 'package:mindvault/domain/entities/note.dart';
import 'package:mindvault/services/analytics_service.dart';
import 'package:mindvault/services/encryption_service.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fake_secure_storage.dart';

class MockNotesDatasource extends Mock implements SupabaseNotesDatasource {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

NoteModel _fakeModel({
  String id = 'note-1',
  String userId = 'user-1',
  String categoryId = 'cat-1',
  String title = 'encrypted-title',
  String body = 'encrypted-body',
  bool isPrivate = false,
  bool isPinned = false,
  int? pinOrder,
  String noteType = 'text',
}) {
  final iso = DateTime.now().toUtc().toIso8601String();
  return NoteModel(
    id: id,
    userId: userId,
    categoryId: categoryId,
    title: title,
    body: body,
    isPrivate: isPrivate,
    lastUsedAt: iso,
    createdAt: iso,
    updatedAt: iso,
    isPinned: isPinned,
    pinOrder: pinOrder,
    noteType: noteType,
  );
}

void main() {
  late MockNotesDatasource remote;
  late AppDatabase db;
  late EncryptionService encService;
  late Key aesKey;
  late NoteRepositoryImpl repo;
  const userId = 'user-1';

  setUp(() {
    remote = MockNotesDatasource();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    encService = EncryptionService(FakeSecureStorage());
    aesKey = encService.generateKey();

    repo = NoteRepositoryImpl(
      remote: remote,
      local: db,
      encryption: encService,
      aesKey: aesKey,
      userId: userId,
    );

    // startSync calls _syncAllNotes — stub it to do nothing by default.
    when(() => remote.fetchAllNotes()).thenAnswer((_) async => []);
    when(() => remote.subscribeToNotes(any())).thenReturn(null);
    when(() => remote.subscribeToChecklistItems(any())).thenReturn(null);
    when(() => remote.fetchAllChecklistItems()).thenAnswer((_) async => []);
    // fetchNoteById used by last-write-wins check in syncPendingOps.
    when(() => remote.fetchNoteById(any())).thenAnswer((_) async => null);
  });

  tearDown(() => db.close());

  // ── createNote ────────────────────────────────────────────────────────────

  group('createNote', () {
    test('writes to Drift before calling Supabase', () async {
      // Make Supabase succeed synchronously but only after we verify Drift.
      var driftWrittenBeforeRemote = false;
      when(() => remote.insertNote(any())).thenAnswer((_) async {
        // At this point at least one note should already be in Drift.
        final rows = await db.select(db.notesTable).get();
        driftWrittenBeforeRemote = rows.isNotEmpty;
        return _fakeModel(
          title: encService.encrypt('Title', aesKey),
          body: encService.encrypt('Body', aesKey),
        );
      });

      await repo.createNote(
        categoryId: 'cat-1',
        title: 'Title',
        body: 'Body',
        isPrivate: false,
      );

      expect(driftWrittenBeforeRemote, isTrue);
    });

    test('returned note has decrypted title and body', () async {
      when(() => remote.insertNote(any())).thenAnswer((_) async => _fakeModel(
            title: encService.encrypt('Hello', aesKey),
            body: encService.encrypt('World', aesKey),
          ));

      final note = await repo.createNote(
        categoryId: 'cat-1',
        title: 'Hello',
        body: 'World',
        isPrivate: false,
      );

      expect(note.title, equals('Hello'));
      expect(note.body, equals('World'));
    });

    test('note is persisted in Drift after successful creation', () async {
      when(() => remote.insertNote(any())).thenAnswer((_) async => _fakeModel(
            title: encService.encrypt('Saved', aesKey),
            body: encService.encrypt('Body', aesKey),
          ));

      final note = await repo.createNote(
        categoryId: 'cat-1',
        title: 'Saved',
        body: 'Body',
        isPrivate: false,
      );

      final fromDb = await db.getNote(note.id);
      expect(fromDb, isNotNull);
      expect(fromDb!.title, equals('Saved'));
    });

    test('queues create_note pending op when Supabase fails', () async {
      when(() => remote.insertNote(any())).thenThrow(Exception('offline'));

      final note = await repo.createNote(
        categoryId: 'cat-1',
        title: 'Offline',
        body: 'Body',
        isPrivate: false,
      );

      final ops = await db.getPendingOps();
      expect(ops.length, equals(1));
      expect(ops.first.opType, equals('create_note'));
      expect(ops.first.recordId, equals(note.id));
    });

    test('note stays in Drift even when Supabase fails', () async {
      when(() => remote.insertNote(any())).thenThrow(Exception('offline'));

      final note = await repo.createNote(
        categoryId: 'cat-1',
        title: 'Offline',
        body: 'Body',
        isPrivate: false,
      );

      expect(await db.getNote(note.id), isNotNull);
    });

    test('Supabase payload includes timestamps', () async {
      Map<String, dynamic>? capturedData;
      when(() => remote.insertNote(any())).thenAnswer((inv) async {
        capturedData = inv.positionalArguments.first as Map<String, dynamic>;
        return _fakeModel(
          title: encService.encrypt('T', aesKey),
          body: encService.encrypt('B', aesKey),
        );
      });

      await repo.createNote(
        categoryId: 'cat-1',
        title: 'T',
        body: 'B',
        isPrivate: false,
      );

      expect(capturedData, isNotNull);
      expect(capturedData!.containsKey('created_at'), isTrue);
      expect(capturedData!.containsKey('updated_at'), isTrue);
      expect(capturedData!.containsKey('last_used_at'), isTrue);
    });
  });

  // ── updateNote ────────────────────────────────────────────────────────────

  group('updateNote', () {
    setUp(() async {
      // Pre-populate Drift with an existing note.
      final now = DateTime.now().toUtc();
      await db.upsertNote(NotesTableCompanion(
        id: const Value('note-1'),
        userId: const Value(userId),
        categoryId: const Value('cat-1'),
        title: const Value('Original'),
        body: const Value('Body'),
        isPrivate: const Value(false),
        lastUsedAt: Value(now),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));
    });

    test('updates Drift immediately', () async {
      when(() => remote.updateNote(any(), any()))
          .thenAnswer((_) async => _fakeModel(
                title: encService.encrypt('Updated', aesKey),
                body: encService.encrypt('Body', aesKey),
              ));

      await repo.updateNote(id: 'note-1', title: 'Updated');

      final row = await db.getNote('note-1');
      expect(row!.title, equals('Updated'));
    });

    test('partial update preserves untouched fields', () async {
      when(() => remote.updateNote(any(), any()))
          .thenAnswer((_) async => _fakeModel(
                title: encService.encrypt('Original', aesKey),
                body: encService.encrypt('New Body', aesKey),
              ));

      final note = await repo.updateNote(id: 'note-1', body: 'New Body');
      expect(note.title, equals('Original'));
      expect(note.body, equals('New Body'));
    });

    test('queues update_note pending op when Supabase fails', () async {
      when(() => remote.updateNote(any(), any()))
          .thenThrow(Exception('offline'));

      await repo.updateNote(id: 'note-1', title: 'Changed');

      final ops = await db.getPendingOps();
      expect(ops.any((o) => o.opType == 'update_note'), isTrue);
    });
  });

  // ── deleteNote ────────────────────────────────────────────────────────────

  group('deleteNote', () {
    setUp(() async {
      final now = DateTime.now().toUtc();
      await db.upsertNote(NotesTableCompanion(
        id: const Value('note-1'),
        userId: const Value(userId),
        categoryId: const Value('cat-1'),
        title: const Value('To Delete'),
        body: const Value(''),
        isPrivate: const Value(false),
        lastUsedAt: Value(now),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));
      await db.upsertPendingOp('note-1', 'create_note', 'note-1');
    });

    test('removes note from Drift immediately', () async {
      when(() => remote.deleteNote(any())).thenAnswer((_) async {});
      await repo.deleteNote('note-1');
      expect(await db.getNote('note-1'), isNull);
    });

    test('clears pending ops for the deleted note', () async {
      when(() => remote.deleteNote(any())).thenAnswer((_) async {});
      await repo.deleteNote('note-1');
      expect(await db.getPendingOps(), isEmpty);
    });

    test('queues delete_note pending op when Supabase fails', () async {
      when(() => remote.deleteNote(any())).thenThrow(Exception('offline'));
      await repo.deleteNote('note-1');
      final ops = await db.getPendingOps();
      expect(
          ops.any((o) => o.opType == 'delete_note' && o.recordId == 'note-1'),
          isTrue);
    });

    test('removes AI history entries citing the deleted note', () async {
      // Insert a history entry that cites note-1
      await db.insertHistory(
        queryHash: 'h1',
        query: 'about the note',
        answer: 'The answer',
        citedTitles: ['To Delete'],
        citedNoteIds: ['note-1'],
      );
      when(() => remote.deleteNote(any())).thenAnswer((_) async {});
      await repo.deleteNote('note-1');
      final history = await db.watchHistory().first;
      expect(
          history.any((e) => e.citedNoteIdsJson.contains('note-1')), isFalse);
    });
  });

  // ── syncPendingOps ────────────────────────────────────────────────────────

  group('syncPendingOps', () {
    test('sends create_note op to Supabase with timestamps', () async {
      final now = DateTime.now().toUtc();
      await db.upsertNote(NotesTableCompanion(
        id: const Value('note-2'),
        userId: const Value(userId),
        categoryId: const Value('cat-1'),
        title: const Value('Queued'),
        body: const Value(''),
        isPrivate: const Value(false),
        lastUsedAt: Value(now),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));
      await db.upsertPendingOp('note-2', 'create_note', 'note-2');

      Map<String, dynamic>? payload;
      when(() => remote.upsertNote(any())).thenAnswer((inv) async {
        payload = inv.positionalArguments.first as Map<String, dynamic>;
      });
      when(() => remote.fetchAllNotes()).thenAnswer((_) async => []);

      await repo.syncPendingOps();

      expect(payload, isNotNull);
      expect(payload!.containsKey('created_at'), isTrue);
      expect(payload!.containsKey('updated_at'), isTrue);
      expect(payload!.containsKey('last_used_at'), isTrue);
    });

    test('deletes pending op after successful sync', () async {
      final now = DateTime.now().toUtc();
      await db.upsertNote(NotesTableCompanion(
        id: const Value('note-3'),
        userId: const Value(userId),
        categoryId: const Value('cat-1'),
        title: const Value('Pending'),
        body: const Value(''),
        isPrivate: const Value(false),
        lastUsedAt: Value(now),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));
      await db.upsertPendingOp('note-3', 'create_note', 'note-3');

      when(() => remote.upsertNote(any())).thenAnswer((_) async {});
      when(() => remote.fetchAllNotes()).thenAnswer((_) async => []);

      await repo.syncPendingOps();

      expect(await db.getPendingOps(), isEmpty);
    });

    test('keeps all failed ops queued when Supabase is unreachable', () async {
      final now = DateTime.now().toUtc();
      for (final id in ['n1', 'n2']) {
        await db.upsertNote(NotesTableCompanion(
          id: Value(id),
          userId: const Value(userId),
          categoryId: const Value('cat-1'),
          title: Value(id),
          body: const Value(''),
          isPrivate: const Value(false),
          lastUsedAt: Value(now),
          createdAt: Value(now),
          updatedAt: Value(now),
        ));
        await db.upsertPendingOp(id, 'create_note', id);
      }

      when(() => remote.upsertNote(any())).thenThrow(Exception('offline'));
      when(() => remote.fetchAllNotes()).thenAnswer((_) async => []);

      await repo.syncPendingOps();

      // Both ops must remain — individual failures do not prevent other ops from being tried.
      expect((await db.getPendingOps()).length, equals(2));
    });

    test('retries create_note op on second call after first call failed',
        () async {
      // Regression: notes were queued with a create_note op while offline.
      // The first syncPendingOps() call fails (e.g. FK violation — category not yet
      // in Supabase). The op must stay queued so a second call (after categories are
      // synced) can succeed. This mirrors the fix in app_router.dart that ensures
      // categories are pushed before notes.
      final now = DateTime.now().toUtc();
      await db.upsertNote(NotesTableCompanion(
        id: const Value('note-retry'),
        userId: const Value(userId),
        categoryId: const Value('cat-new'),
        title: const Value('Offline Note'),
        body: const Value(''),
        isPrivate: const Value(false),
        lastUsedAt: Value(now),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));
      await db.upsertPendingOp('note-retry', 'create_note', 'note-retry');

      // First call: Supabase rejects (category doesn't exist yet).
      when(() => remote.upsertNote(any())).thenThrow(Exception('FK violation'));
      when(() => remote.fetchAllNotes()).thenAnswer((_) async => []);
      await repo.syncPendingOps();
      expect((await db.getPendingOps()).length, equals(1),
          reason: 'op must remain queued after first failure');

      // Second call: category is now in Supabase, note succeeds.
      when(() => remote.upsertNote(any())).thenAnswer((_) async {});
      await repo.syncPendingOps();
      expect(await db.getPendingOps(), isEmpty,
          reason: 'op must be cleared after successful retry');
    });

    test('sends delete_note op to Supabase', () async {
      await db.upsertPendingOp('del_note-x', 'delete_note', 'note-x');

      when(() => remote.deleteNote('note-x')).thenAnswer((_) async {});
      when(() => remote.fetchAllNotes()).thenAnswer((_) async => []);

      await repo.syncPendingOps();

      verify(() => remote.deleteNote('note-x')).called(1);
      expect(await db.getPendingOps(), isEmpty);
    });

    test(
        'delete_note op removes note from Drift even if Realtime re-inserted it',
        () async {
      // Regression: note created ONLINE (in Supabase), deleted OFFLINE (Drift removed,
      // delete_note op queued). On reconnect, Supabase Realtime re-fires the note row
      // as an INSERT → Realtime handler upserts it back into Drift. syncPendingOps must
      // then delete from Supabase AND also re-delete from Drift.
      final now = DateTime.now().toUtc();
      // Simulate Realtime having re-inserted the note into Drift.
      await db.upsertNote(NotesTableCompanion(
        id: const Value('note-deleted'),
        userId: const Value(userId),
        categoryId: const Value('cat-1'),
        title: const Value('Should be gone'),
        body: const Value(''),
        isPrivate: const Value(false),
        lastUsedAt: Value(now),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));
      await db.upsertPendingOp(
          'del_note-deleted', 'delete_note', 'note-deleted');

      when(() => remote.deleteNote('note-deleted')).thenAnswer((_) async {});
      when(() => remote.fetchAllNotes()).thenAnswer((_) async => []);

      await repo.syncPendingOps();

      verify(() => remote.deleteNote('note-deleted')).called(1);
      expect(await db.getPendingOps(), isEmpty);
      expect(await db.getNote('note-deleted'), isNull,
          reason:
              'note must be gone from Drift after delete_note op is processed');
    });

    test('syncPendingOps processes all ops even when one fails', () async {
      // Regression: with the old break-on-first-failure logic, a transient error on
      // op A would prevent op B from being processed. Both ops must be attempted.
      final now = DateTime.now().toUtc();
      await db.upsertNote(NotesTableCompanion(
        id: const Value('note-fail'),
        userId: const Value(userId),
        categoryId: const Value('cat-1'),
        title: const Value('Fail'),
        body: const Value(''),
        isPrivate: const Value(false),
        lastUsedAt: Value(now),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));
      await db.upsertNote(NotesTableCompanion(
        id: const Value('note-ok'),
        userId: const Value(userId),
        categoryId: const Value('cat-1'),
        title: const Value('OK'),
        body: const Value(''),
        isPrivate: const Value(false),
        lastUsedAt: Value(now),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));
      await db.upsertPendingOp('note-fail', 'create_note', 'note-fail');
      await db.upsertPendingOp('note-ok', 'create_note', 'note-ok');

      // First note fails, second succeeds.
      var callCount = 0;
      when(() => remote.upsertNote(any())).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) throw Exception('transient error');
      });
      when(() => remote.fetchAllNotes()).thenAnswer((_) async => []);

      await repo.syncPendingOps();

      final remaining = await db.getPendingOps();
      expect(remaining.length, equals(1),
          reason: 'only the failed op should remain');
      expect(remaining.first.recordId, equals('note-fail'));
    });
  });

  test('skips stale update_note op when remote already has a newer version',
      () async {
    // Scenario: note edited offline on Device A (oldTime), then edited online
    // on Device B (newTime). When Device A reconnects, its pending op must NOT
    // overwrite Device B's newer content.
    final oldTime = DateTime(2024, 1, 1).toUtc();
    final newTime = DateTime(2024, 6, 1).toUtc();

    await db.upsertNote(NotesTableCompanion(
      id: const Value('note-stale'),
      userId: const Value(userId),
      categoryId: const Value('cat-1'),
      title: const Value('Old Edit'),
      body: const Value(''),
      isPrivate: const Value(false),
      lastUsedAt: Value(oldTime),
      createdAt: Value(oldTime),
      updatedAt: Value(oldTime),
    ));
    await db.upsertPendingOp('note-stale', 'update_note', 'note-stale');

    final remoteModel = NoteModel(
      id: 'note-stale',
      userId: userId,
      categoryId: 'cat-1',
      title: encService.encrypt('Newer Edit', aesKey),
      body: encService.encrypt('', aesKey),
      isPrivate: false,
      lastUsedAt: newTime.toIso8601String(),
      createdAt: oldTime.toIso8601String(),
      updatedAt: newTime.toIso8601String(),
    );
    when(() => remote.fetchNoteById('note-stale'))
        .thenAnswer((_) async => remoteModel);
    when(() => remote.fetchAllNotes()).thenAnswer((_) async => [remoteModel]);

    await repo.syncPendingOps();

    verifyNever(() => remote.upsertNote(any()));
    expect(await db.getPendingOps(), isEmpty,
        reason: 'stale pending op must be cleared');
    final local = await db.getNote('note-stale');
    // Drift returns local-timezone DateTimes; compare via toUtc() to avoid
    // isUtc-flag mismatch in DateTime ==.
    expect(local?.updatedAt.toUtc(), equals(newTime),
        reason: '_syncAllNotes must have pulled the newer remote version');
  });

  test('pushes update_note op when local is newer than remote', () async {
    final oldTime = DateTime(2024, 1, 1).toUtc();
    final newTime = DateTime(2024, 6, 1).toUtc();

    await db.upsertNote(NotesTableCompanion(
      id: const Value('note-newer'),
      userId: const Value(userId),
      categoryId: const Value('cat-1'),
      title: const Value('Fresh Edit'),
      body: const Value(''),
      isPrivate: const Value(false),
      lastUsedAt: Value(newTime),
      createdAt: Value(oldTime),
      updatedAt: Value(newTime),
    ));
    await db.upsertPendingOp('note-newer', 'update_note', 'note-newer');

    // Remote has an older version.
    final remoteModel = NoteModel(
      id: 'note-newer',
      userId: userId,
      categoryId: 'cat-1',
      title: encService.encrypt('Old Remote', aesKey),
      body: encService.encrypt('', aesKey),
      isPrivate: false,
      lastUsedAt: oldTime.toIso8601String(),
      createdAt: oldTime.toIso8601String(),
      updatedAt: oldTime.toIso8601String(),
    );
    when(() => remote.fetchNoteById('note-newer'))
        .thenAnswer((_) async => remoteModel);
    when(() => remote.upsertNote(any())).thenAnswer((_) async {});
    when(() => remote.fetchAllNotes()).thenAnswer((_) async => []);

    await repo.syncPendingOps();

    verify(() => remote.upsertNote(any())).called(1);
    expect(await db.getPendingOps(), isEmpty);
  });

  test('cleans up update_note pending op when local note no longer exists',
      () async {
    // Note was deleted locally after the pending op was created.
    await db.upsertPendingOp('ghost-note', 'update_note', 'ghost-note');
    when(() => remote.fetchAllNotes()).thenAnswer((_) async => []);

    await repo.syncPendingOps();

    verifyNever(() => remote.upsertNote(any()));
    expect(await db.getPendingOps(), isEmpty,
        reason:
            'orphaned pending op for a locally-deleted note must be cleared');
  });

  // ── _syncAllNotes (via syncPendingOps) ────────────────────────────────────

  group('_syncAllNotes reconciliation', () {
    test('removes Drift note absent from Supabase with no pending create op',
        () async {
      // Simulates: note deleted offline, Realtime re-inserted it, syncPendingOps runs.
      // After the delete op is processed, _syncAllNotes must clean up Drift.
      final now = DateTime.now().toUtc();
      await db.upsertNote(NotesTableCompanion(
        id: const Value('stale-note'),
        userId: const Value(userId),
        categoryId: const Value('cat-1'),
        title: const Value('Stale'),
        body: const Value(''),
        isPrivate: const Value(false),
        lastUsedAt: Value(now),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));
      // No pending op — this note is not in Supabase and shouldn't exist locally.
      when(() => remote.fetchAllNotes()).thenAnswer((_) async => []);

      await repo.syncPendingOps();

      expect(await db.getNote('stale-note'), isNull,
          reason: 'Drift must not keep a note that is absent from Supabase');
    });

    test('does NOT remove Drift note that has a pending create_note op',
        () async {
      // Note was created offline — it is in Drift but not yet in Supabase.
      // _syncAllNotes must not delete it because the pending op will push it later.
      final now = DateTime.now().toUtc();
      await db.upsertNote(NotesTableCompanion(
        id: const Value('offline-note'),
        userId: const Value(userId),
        categoryId: const Value('cat-1'),
        title: const Value('Offline'),
        body: const Value(''),
        isPrivate: const Value(false),
        lastUsedAt: Value(now),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));
      await db.upsertPendingOp('offline-note', 'create_note', 'offline-note');

      when(() => remote.upsertNote(any()))
          .thenThrow(Exception('still offline'));
      when(() => remote.fetchAllNotes()).thenAnswer((_) async => []);

      await repo.syncPendingOps();

      expect(await db.getNote('offline-note'), isNotNull,
          reason: 'pending create note must be preserved in Drift');
    });
  });

  // ── setNotePinned ─────────────────────────────────────────────────────────

  group('setNotePinned', () {
    final now = DateTime.now().toUtc();

    setUp(() async {
      await db.upsertNote(NotesTableCompanion(
        id: const Value('note-1'),
        userId: const Value(userId),
        categoryId: const Value('cat-1'),
        title: const Value('Note'),
        body: const Value(''),
        isPrivate: const Value(false),
        lastUsedAt: Value(now),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));
    });

    test('pinning sets isPinned=true and pinOrder=0 when no pinned notes exist',
        () async {
      when(() => remote.updateNote(any(), any()))
          .thenAnswer((_) async => _fakeModel(
                title: encService.encrypt('Note', aesKey),
                body: encService.encrypt('', aesKey),
                isPinned: true,
                pinOrder: 0,
              ));

      await repo.setNotePinned(id: 'note-1', isPinned: true);

      final row = await db.getNote('note-1');
      expect(row!.isPinned, isTrue);
      expect(row.pinOrder, equals(0));
      expect(row.pinnedAt, isNotNull);
    });

    test('pinning a second note assigns pinOrder=1', () async {
      // Seed an already-pinned note with pinOrder=0
      await db.upsertNote(NotesTableCompanion(
        id: const Value('note-pinned'),
        userId: const Value(userId),
        categoryId: const Value('cat-1'),
        title: const Value('Already Pinned'),
        body: const Value(''),
        isPrivate: const Value(false),
        lastUsedAt: Value(now),
        createdAt: Value(now),
        updatedAt: Value(now),
        isPinned: const Value(true),
        pinOrder: const Value(0),
      ));

      when(() => remote.updateNote(any(), any()))
          .thenAnswer((_) async => _fakeModel(
                title: encService.encrypt('Note', aesKey),
                body: encService.encrypt('', aesKey),
                isPinned: true,
                pinOrder: 1,
              ));

      await repo.setNotePinned(id: 'note-1', isPinned: true);

      final row = await db.getNote('note-1');
      expect(row!.pinOrder, equals(1));
    });

    test('unpinning clears isPinned, pinOrder, and pinnedAt', () async {
      // Pre-seed as pinned
      await db.upsertNote(NotesTableCompanion(
        id: const Value('note-1'),
        userId: const Value(userId),
        categoryId: const Value('cat-1'),
        title: const Value('Note'),
        body: const Value(''),
        isPrivate: const Value(false),
        lastUsedAt: Value(now),
        createdAt: Value(now),
        updatedAt: Value(now),
        isPinned: const Value(true),
        pinnedAt: Value(now),
        pinOrder: const Value(0),
      ));

      when(() => remote.updateNote(any(), any()))
          .thenAnswer((_) async => _fakeModel(
                title: encService.encrypt('Note', aesKey),
                body: encService.encrypt('', aesKey),
              ));

      await repo.setNotePinned(id: 'note-1', isPinned: false);

      final row = await db.getNote('note-1');
      expect(row!.isPinned, isFalse);
      expect(row.pinOrder, isNull);
      expect(row.pinnedAt, isNull);
    });

    test('queues update_note pending op when remote fails', () async {
      when(() => remote.updateNote(any(), any()))
          .thenThrow(Exception('offline'));

      await repo.setNotePinned(id: 'note-1', isPinned: true);

      final ops = await db.getPendingOps();
      expect(
          ops.any((o) => o.opType == 'update_note' && o.recordId == 'note-1'),
          isTrue);
    });

    test('local isPinned change is visible even if remote fails', () async {
      when(() => remote.updateNote(any(), any()))
          .thenThrow(Exception('offline'));

      await repo.setNotePinned(id: 'note-1', isPinned: true);

      final row = await db.getNote('note-1');
      expect(row!.isPinned, isTrue);
    });

    test(
        'setNotePinned bumps updatedAt so offline changes participate in last-write-wins',
        () async {
      // Re-seed with a clearly-old timestamp so even second-precision Drift storage
      // can distinguish the bumped value from the original.
      final old = DateTime(2024, 1, 1).toUtc();
      await db.upsertNote(NotesTableCompanion(
        id: const Value('note-1'),
        userId: const Value(userId),
        categoryId: const Value('cat-1'),
        title: const Value('Note'),
        body: const Value(''),
        isPrivate: const Value(false),
        lastUsedAt: Value(old),
        createdAt: Value(old),
        updatedAt: Value(old),
      ));

      when(() => remote.updateNote(any(), any()))
          .thenThrow(Exception('offline'));
      await repo.setNotePinned(id: 'note-1', isPinned: true);

      final row = await db.getNote('note-1');
      expect(row!.updatedAt.isAfter(old), isTrue,
          reason:
              'updatedAt must be refreshed so the pending op carries a current timestamp');
    });
  });

  // ── reorderPinnedNotes ───────────────────────────────────────────────────

  group('reorderPinnedNotes', () {
    final now = DateTime.now().toUtc();

    setUp(() async {
      for (final id in ['note-a', 'note-b', 'note-c']) {
        await db.upsertNote(NotesTableCompanion(
          id: Value(id),
          userId: const Value(userId),
          categoryId: const Value('cat-1'),
          title: Value(id),
          body: const Value(''),
          isPrivate: const Value(false),
          lastUsedAt: Value(now),
          createdAt: Value(now),
          updatedAt: Value(now),
          isPinned: const Value(true),
          pinOrder: Value(['note-a', 'note-b', 'note-c'].indexOf(id)),
        ));
      }
    });

    test('rewrites pinOrder to match the supplied ordering', () async {
      when(() => remote.updatePinOrders(any())).thenAnswer((_) async {});

      await repo.reorderPinnedNotes(['note-c', 'note-a', 'note-b']);

      expect((await db.getNote('note-c'))!.pinOrder, equals(0));
      expect((await db.getNote('note-a'))!.pinOrder, equals(1));
      expect((await db.getNote('note-b'))!.pinOrder, equals(2));
    });

    test('queues update_note ops for each pinned note when remote fails',
        () async {
      when(() => remote.updatePinOrders(any())).thenThrow(Exception('offline'));

      await repo.reorderPinnedNotes(['note-c', 'note-a', 'note-b']);

      final ops = await db.getPendingOps();
      final opIds = ops.map((o) => o.recordId).toSet();
      expect(opIds, containsAll(['note-a', 'note-b', 'note-c']));
    });

    test(
        'reorderPinnedNotes bumps updatedAt so offline reorders participate in last-write-wins',
        () async {
      // Re-seed all three notes with a clearly-old updatedAt.
      final old = DateTime(2024, 1, 1).toUtc();
      for (final id in ['note-a', 'note-b', 'note-c']) {
        await db.upsertNote(NotesTableCompanion(
          id: Value(id),
          userId: const Value(userId),
          categoryId: const Value('cat-1'),
          title: Value(id),
          body: const Value(''),
          isPrivate: const Value(false),
          lastUsedAt: Value(old),
          createdAt: Value(old),
          updatedAt: Value(old),
          isPinned: const Value(true),
          pinOrder: Value(['note-a', 'note-b', 'note-c'].indexOf(id)),
        ));
      }

      when(() => remote.updatePinOrders(any())).thenAnswer((_) async {});
      await repo.reorderPinnedNotes(['note-c', 'note-a', 'note-b']);

      for (final id in ['note-a', 'note-b', 'note-c']) {
        final row = await db.getNote(id);
        expect(row!.updatedAt.isAfter(old), isTrue,
            reason: '$id updatedAt must be refreshed after reorder');
      }
    });
  });

  // ── syncPendingOps includes pin fields ────────────────────────────────────

  group('syncPendingOps pin fields', () {
    test('pending upsert includes is_pinned, pinned_at, pin_order', () async {
      final now = DateTime.now().toUtc();
      await db.upsertNote(NotesTableCompanion(
        id: const Value('note-pin'),
        userId: const Value(userId),
        categoryId: const Value('cat-1'),
        title: const Value('Pinned'),
        body: const Value(''),
        isPrivate: const Value(false),
        lastUsedAt: Value(now),
        createdAt: Value(now),
        updatedAt: Value(now),
        isPinned: const Value(true),
        pinnedAt: Value(now),
        pinOrder: const Value(0),
      ));
      await db.upsertPendingOp('note-pin', 'update_note', 'note-pin');

      Map<String, dynamic>? payload;
      when(() => remote.upsertNote(any())).thenAnswer((inv) async {
        payload = inv.positionalArguments.first as Map<String, dynamic>;
      });
      when(() => remote.fetchAllNotes()).thenAnswer((_) async => []);

      await repo.syncPendingOps();

      expect(payload!['is_pinned'], isTrue);
      expect(payload!['pin_order'], equals(0));
    });
  });

  group('checklist notes', () {
    setUp(() async {
      final now = DateTime.now().toUtc();
      await db.upsertNote(NotesTableCompanion(
        id: const Value('check-note'),
        userId: const Value(userId),
        categoryId: const Value('cat-1'),
        title: const Value('Tasks'),
        body: const Value('One\n\nTwo'),
        isPrivate: const Value(false),
        lastUsedAt: Value(now),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));
      when(() => remote.updateNote(any(), any()))
          .thenAnswer((_) async => _fakeModel(
                id: 'check-note',
                title: encService.encrypt('Tasks', aesKey),
                body: encService.encrypt('One\nTwo', aesKey),
                noteType: 'checklist',
              ));
      when(() => remote.upsertChecklistItems(any())).thenAnswer((_) async {});
      when(() => remote.deleteChecklistItem(any())).thenAnswer((_) async {});
    });

    test('converting text to checklist drops empty lines and creates items',
        () async {
      await repo.convertNoteType(
        noteId: 'check-note',
        noteType: NoteType.checklist,
      );

      final note = await db.getNote('check-note');
      final items = await db.getChecklistItems('check-note');
      expect(note!.noteType, equals('checklist'));
      expect(note.body, equals('One\nTwo'));
      expect(items.map((i) => i.itemText), equals(['One', 'Two']));
      expect(items.every((i) => !i.isCompleted), isTrue);
    });

    test('replaceChecklistItems encrypts remote item text', () async {
      List<Map<String, dynamic>>? payload;
      when(() => remote.upsertChecklistItems(any())).thenAnswer((inv) async {
        payload = (inv.positionalArguments.first as List)
            .cast<Map<String, dynamic>>();
      });

      await repo.replaceChecklistItems(
        noteId: 'check-note',
        texts: ['Secret task'],
      );

      expect(payload, isNotNull);
      expect(payload!.single['text'], isNot(equals('Secret task')));
      expect(encService.decrypt(payload!.single['text'] as String, aesKey),
          equals('Secret task'));
    });

    test(
        'replaceChecklistItems preserves provided completion states for new items',
        () async {
      await repo.replaceChecklistItems(
        noteId: 'check-note',
        texts: ['First', 'Second'],
        completionStates: [true, false],
      );

      final items = await db.getChecklistItems('check-note');
      expect(items.map((item) => item.isCompleted), equals([false, true]));
      expect(items.map((item) => item.itemText), equals(['Second', 'First']));
    });

    test(
        'replaceChecklistItems matches existing items by row id instead of visible index',
        () async {
      final now = DateTime.now().toUtc();
      await db.upsertNote((await db.getNote('check-note'))!
          .copyWith(noteType: 'checklist')
          .toCompanion(false));
      await db.deleteChecklistItemsByNoteId('check-note');
      await db.upsertChecklistItems([
        ChecklistItemsTableCompanion(
          id: const Value('unchecked-a'),
          noteId: const Value('check-note'),
          userId: const Value(userId),
          itemText: const Value('Alpha'),
          isCompleted: const Value(false),
          sortOrder: const Value(0),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
        ChecklistItemsTableCompanion(
          id: const Value('checked-b'),
          noteId: const Value('check-note'),
          userId: const Value(userId),
          itemText: const Value('Beta'),
          isCompleted: const Value(true),
          sortOrder: const Value(0),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      ]);

      await repo.replaceChecklistItems(
        noteId: 'check-note',
        texts: ['Alpha', 'New task', 'Beta'],
        completionStates: [false, false, true],
        rowIds: ['unchecked-a', null, 'checked-b'],
      );

      final items = await db.getChecklistItems('check-note');
      expect(items.map((item) => item.itemText),
          equals(['Alpha', 'New task', 'Beta']));
      expect(
          items.map((item) => item.isCompleted), equals([false, false, true]));
    });

    test(
        'startSync does not overwrite pending offline checklist changes with stale remote data',
        () async {
      final now = DateTime.now().toUtc();
      await db.upsertNote((await db.getNote('check-note'))!
          .copyWith(noteType: 'checklist')
          .toCompanion(false));
      await db.deleteChecklistItemsByNoteId('check-note');
      await db.upsertChecklistItem(ChecklistItemsTableCompanion(
        id: const Value('item-1'),
        noteId: const Value('check-note'),
        userId: const Value(userId),
        itemText: const Value('Local updated'),
        isCompleted: const Value(true),
        sortOrder: const Value(0),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));
      await db.upsertPendingOp('check-note', 'update_note', 'check-note');
      await db.upsertPendingOp('item-1', 'update_checklist_item', 'item-1');

      when(() => remote.fetchAllChecklistItems()).thenAnswer((_) async => [
            ChecklistItemModel(
              id: 'item-1',
              noteId: 'check-note',
              userId: userId,
              text: encService.encrypt('Remote stale', aesKey),
              isCompleted: false,
              sortOrder: 0,
              completedAt: null,
              createdAt: now.toIso8601String(),
              updatedAt: now.toIso8601String(),
            ),
          ]);

      repo.startSync();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final item = await db.getChecklistItem('item-1');
      expect(item!.itemText, equals('Local updated'));
      expect(item.isCompleted, isTrue);
    });

    test(
        'startSync does not restore checklist rows with pending offline deletes',
        () async {
      final now = DateTime.now().toUtc();
      await db.upsertNote((await db.getNote('check-note'))!
          .copyWith(noteType: 'checklist')
          .toCompanion(false));
      await db.deleteChecklistItemsByNoteId('check-note');
      await db.upsertPendingOp('check-note', 'update_note', 'check-note');
      await db.upsertPendingOp(
          'del_checklist_item-1', 'delete_checklist_item', 'item-1');

      when(() => remote.fetchAllChecklistItems()).thenAnswer((_) async => [
            ChecklistItemModel(
              id: 'item-1',
              noteId: 'check-note',
              userId: userId,
              text: encService.encrypt('Remote stale', aesKey),
              isCompleted: true,
              sortOrder: 0,
              completedAt: now.toIso8601String(),
              createdAt: now.toIso8601String(),
              updatedAt: now.toIso8601String(),
            ),
          ]);

      repo.startSync();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(await db.getChecklistItem('item-1'), isNull);
    });

    test(
        'startSync removes local checklist rows deleted remotely while offline',
        () async {
      final now = DateTime.now().toUtc();
      await db.upsertNote((await db.getNote('check-note'))!
          .copyWith(noteType: 'checklist')
          .toCompanion(false));
      await db.deleteChecklistItemsByNoteId('check-note');
      await db.upsertChecklistItem(ChecklistItemsTableCompanion(
        id: const Value('remote-deleted'),
        noteId: const Value('check-note'),
        userId: const Value(userId),
        itemText: const Value('Deleted elsewhere'),
        isCompleted: const Value(false),
        sortOrder: const Value(0),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));
      await db.upsertPendingOp('check-note', 'update_note', 'check-note');

      when(() => remote.fetchAllChecklistItems()).thenAnswer((_) async => []);

      repo.startSync();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(await db.getChecklistItem('remote-deleted'), isNull);
      expect((await db.getNote('check-note'))!.body, isEmpty);
    });

    test(
        'startSync does not overwrite pending offline note changes with stale remote data',
        () async {
      final now = DateTime.now().toUtc();
      await db.upsertNote(NotesTableCompanion(
        id: const Value('offline-note'),
        userId: const Value(userId),
        categoryId: const Value('cat-1'),
        title: const Value('Local title'),
        body: const Value('Local body'),
        isPrivate: const Value(false),
        lastUsedAt: Value(now),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));
      await db.upsertPendingOp('offline-note', 'update_note', 'offline-note');

      when(() => remote.fetchAllNotes()).thenAnswer((_) async => [
            _fakeModel(
              id: 'offline-note',
              title: encService.encrypt('Remote title', aesKey),
              body: encService.encrypt('Remote body', aesKey),
            ),
          ]);

      repo.startSync();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final note = await db.getNote('offline-note');
      expect(note!.title, equals('Local title'));
      expect(note.body, equals('Local body'));
    });

    test('deleteCompletedChecklistItems removes only completed rows', () async {
      final now = DateTime.now().toUtc();
      await db.upsertNote((await db.getNote('check-note'))!
          .copyWith(noteType: 'checklist')
          .toCompanion(false));
      await db.upsertChecklistItems([
        ChecklistItemsTableCompanion(
          id: const Value('todo'),
          noteId: const Value('check-note'),
          userId: const Value(userId),
          itemText: const Value('Keep'),
          isCompleted: const Value(false),
          sortOrder: const Value(0),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
        ChecklistItemsTableCompanion(
          id: const Value('done'),
          noteId: const Value('check-note'),
          userId: const Value(userId),
          itemText: const Value('Remove'),
          isCompleted: const Value(true),
          sortOrder: const Value(1),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      ]);

      await repo.deleteCompletedChecklistItems('check-note');

      final remaining = await db.getChecklistItems('check-note');
      expect(remaining.map((i) => i.id), equals(['todo']));
    });
  });

  // ── searchNotes ───────────────────────────────────────────────────────────

  group('searchNotes', () {
    test('returns empty list when no notes match', () async {
      final results = await repo.searchNotes('nonexistent');
      expect(results, isEmpty);
    });

    test('finds a note by title keyword', () async {
      final now = DateTime.now().toUtc();
      await db.upsertNote(NotesTableCompanion(
        id: const Value('note-search'),
        userId: const Value(userId),
        categoryId: const Value('cat-1'),
        title: const Value('Flutter Testing'),
        body: const Value(''),
        isPrivate: const Value(false),
        lastUsedAt: Value(now),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));

      final results = await repo.searchNotes('Flutter');
      expect(results.any((n) => n.id == 'note-search'), isTrue);
    });

    test('does not return private notes in search results', () async {
      final now = DateTime.now().toUtc();
      await db.upsertNote(NotesTableCompanion(
        id: const Value('private-note'),
        userId: const Value(userId),
        categoryId: const Value('cat-1'),
        title: const Value('Secret Diary'),
        body: const Value(''),
        isPrivate: const Value(true),
        lastUsedAt: Value(now),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));

      final results = await repo.searchNotes('Secret');
      expect(results.any((n) => n.id == 'private-note'), isFalse);
    });
  });

  // ── analytics tracking ────────────────────────────────────────────────────

  group('analytics tracking', () {
    late MockAnalyticsService analytics;
    late NoteRepositoryImpl repoWithAnalytics;

    setUp(() {
      analytics = MockAnalyticsService();
      repoWithAnalytics = NoteRepositoryImpl(
        remote: remote,
        local: db,
        encryption: encService,
        aesKey: aesKey,
        userId: userId,
        analytics: analytics,
      );
    });

    test('createNote fires note_created event', () async {
      when(() => remote.insertNote(any())).thenAnswer((_) async => _fakeModel(
            title: encService.encrypt('Title', aesKey),
            body: encService.encrypt('Body', aesKey),
          ));

      await repoWithAnalytics.createNote(
        categoryId: 'cat-1',
        title: 'Title',
        body: 'Body',
        isPrivate: false,
      );

      verify(() =>
              analytics.track('note_created', metadata: any(named: 'metadata')))
          .called(1);
    });

    test('createNote fires note_created even when Supabase is offline',
        () async {
      when(() => remote.insertNote(any()))
          .thenThrow(Exception('network error'));

      await repoWithAnalytics.createNote(
        categoryId: 'cat-1',
        title: 'Offline',
        body: '',
        isPrivate: false,
      );

      verify(() =>
              analytics.track('note_created', metadata: any(named: 'metadata')))
          .called(1);
    });

    test('deleteNote fires note_deleted event', () async {
      final now = DateTime.now().toUtc();
      await db.upsertNote(NotesTableCompanion(
        id: const Value('del-note'),
        userId: const Value(userId),
        categoryId: const Value('cat-1'),
        title: const Value('To delete'),
        body: const Value(''),
        isPrivate: const Value(false),
        lastUsedAt: Value(now),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));
      when(() => remote.deleteNote(any())).thenAnswer((_) async {});

      await repoWithAnalytics.deleteNote('del-note');

      verify(() =>
              analytics.track('note_deleted', metadata: any(named: 'metadata')))
          .called(1);
    });

    test('analytics is optional — null analytics does not throw', () async {
      // repo (no analytics) was constructed in the outer setUp without analytics param.
      when(() => remote.insertNote(any())).thenAnswer((_) async => _fakeModel(
            title: encService.encrypt('T', aesKey),
            body: encService.encrypt('B', aesKey),
          ));

      await expectLater(
        repo.createNote(
            categoryId: 'cat-1', title: 'T', body: 'B', isPrivate: false),
        completes,
      );
    });
  });
}
