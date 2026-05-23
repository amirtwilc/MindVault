import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindvault/data/local/database/app_database.dart';
import 'package:mindvault/data/models/note_reminder_model.dart';
import 'package:mindvault/data/remote/supabase/supabase_notes_datasource.dart';
import 'package:mindvault/data/repositories/reminder_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

class _MockNotesDatasource extends Mock implements SupabaseNotesDatasource {}

NoteReminderModel _model({
  String noteId = 'note-1',
  String userId = 'user-1',
  DateTime? remindAt,
  DateTime? updatedAt,
  DateTime? deletedAt,
}) {
  final now = DateTime(2024, 1, 1).toUtc();
  return NoteReminderModel(
    noteId: noteId,
    userId: userId,
    remindAt: (remindAt ?? now.add(const Duration(hours: 1))).toIso8601String(),
    createdAt: now.toIso8601String(),
    updatedAt: (updatedAt ?? now).toIso8601String(),
    deletedAt: deletedAt?.toIso8601String(),
  );
}

Future<void> _seedNote(AppDatabase db) async {
  final now = DateTime(2024, 1, 1).toUtc();
  await db.upsertNote(NotesTableCompanion(
    id: const Value('note-1'),
    userId: const Value('user-1'),
    categoryId: const Value('cat-1'),
    title: const Value('Note'),
    body: const Value(''),
    isPrivate: const Value(false),
    lastUsedAt: Value(now),
    createdAt: Value(now),
    updatedAt: Value(now),
  ));
}

void main() {
  late AppDatabase db;
  late _MockNotesDatasource remote;
  late ReminderRepositoryImpl repo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    remote = _MockNotesDatasource();
    repo = ReminderRepositoryImpl(
      remote: remote,
      local: db,
      userId: 'user-1',
    );
    await _seedNote(db);
    when(() => remote.fetchAllReminders()).thenAnswer((_) async => []);
    when(() => remote.subscribeToReminders(any())).thenReturn(null);
  });

  tearDown(() async {
    await db.close();
  });

  test('setReminder writes locally before remote call', () async {
    var localWasWritten = false;
    when(() => remote.upsertReminder(any())).thenAnswer((inv) async {
      localWasWritten = await db.getReminder('note-1') != null;
      return _model();
    });

    await repo.setReminder(
      'note-1',
      DateTime.now().toUtc().add(const Duration(hours: 1)),
    );

    expect(localWasWritten, isTrue);
  });

  test('setReminder queues pending op when remote fails', () async {
    when(() => remote.upsertReminder(any())).thenThrow(Exception('offline'));

    await repo.setReminder(
      'note-1',
      DateTime.now().toUtc().add(const Duration(hours: 1)),
    );

    final ops = await db.getPendingOps();
    expect(ops.single.opType, 'upsert_reminder');
    expect(ops.single.recordId, 'note-1');
  });

  test('removeReminder soft deletes locally and queues when remote fails',
      () async {
    when(() => remote.upsertReminder(any())).thenThrow(Exception('offline'));
    await db.upsertReminder(NoteRemindersTableCompanion(
      noteId: const Value('note-1'),
      userId: const Value('user-1'),
      remindAt: Value(DateTime.now().toUtc().add(const Duration(hours: 1))),
      createdAt: Value(DateTime.now().toUtc()),
      updatedAt: Value(DateTime.now().toUtc()),
    ));

    await repo.removeReminder('note-1');

    final reminder = await db.getReminder('note-1');
    expect(reminder!.deletedAt, isNotNull);
    expect((await db.getPendingOps()).single.opType, 'delete_reminder');
  });

  test('cleanupExpiredReminders removes reminders whose time has passed',
      () async {
    final now = DateTime(2024, 1, 3).toUtc();
    when(() => remote.upsertReminder(any())).thenAnswer((_) async => _model(
          remindAt: now.subtract(const Duration(days: 2)),
          updatedAt: now,
          deletedAt: now,
        ));
    await db.upsertReminder(NoteRemindersTableCompanion(
      noteId: const Value('note-1'),
      userId: const Value('user-1'),
      remindAt: Value(now.subtract(const Duration(days: 2))),
      createdAt: Value(now.subtract(const Duration(days: 3))),
      updatedAt: Value(now.subtract(const Duration(days: 3))),
    ));

    await repo.cleanupExpiredReminders(now);

    expect((await db.getReminder('note-1'))!.deletedAt, isNotNull);
  });

  test('syncPendingOps sends queued reminder payload and clears op', () async {
    final remindAt = DateTime.now().toUtc().add(const Duration(hours: 1));
    await db.upsertReminder(NoteRemindersTableCompanion(
      noteId: const Value('note-1'),
      userId: const Value('user-1'),
      remindAt: Value(remindAt),
      createdAt: Value(DateTime.now().toUtc()),
      updatedAt: Value(DateTime.now().toUtc()),
    ));
    await db.upsertPendingOp('reminder_note-1', 'upsert_reminder', 'note-1');

    Map<String, dynamic>? payload;
    when(() => remote.upsertReminder(any())).thenAnswer((inv) async {
      payload = inv.positionalArguments.first as Map<String, dynamic>;
      return _model(remindAt: remindAt);
    });

    await repo.syncPendingOps();

    expect(payload!['note_id'], 'note-1');
    expect(await db.getPendingOps(), isEmpty);
  });

  test('syncAllReminders stores reminder even when note is not local yet',
      () async {
    final remindAt = DateTime.now().toUtc().add(const Duration(hours: 1));
    when(() => remote.fetchAllReminders()).thenAnswer(
      (_) async => [
        _model(noteId: 'remote-note', remindAt: remindAt),
      ],
    );

    await repo.syncAllReminders();

    final reminder = await db.getReminder('remote-note');
    expect(reminder, isNotNull);
    expect(reminder!.noteId, 'remote-note');
  });
}
