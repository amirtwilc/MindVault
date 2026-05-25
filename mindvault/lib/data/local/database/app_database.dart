import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

// ── Tables ────────────────────────────────────────────────────

class CategoriesTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().named('user_id')();
  TextColumn get name => text()();
  IntColumn get sortOrder =>
      integer().named('sort_order').withDefault(const Constant(0))();
  DateTimeColumn get lastUsedAt => dateTime().named('last_used_at')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  TextColumn get color => text().named('color').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class NotesTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().named('user_id')();
  TextColumn get categoryId => text().named('category_id')();
  TextColumn get title => text()();
  TextColumn get body => text().withDefault(const Constant(''))();
  BoolColumn get isPrivate =>
      boolean().named('is_private').withDefault(const Constant(false))();
  DateTimeColumn get lastUsedAt => dateTime().named('last_used_at')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  DateTimeColumn get lastOpenedAt =>
      dateTime().named('last_opened_at').nullable()();
  TextColumn get noteType =>
      text().named('note_type').withDefault(const Constant('text'))();
  BoolColumn get isPinned =>
      boolean().named('is_pinned').withDefault(const Constant(false))();
  DateTimeColumn get pinnedAt => dateTime().named('pinned_at').nullable()();
  IntColumn get pinOrder => integer().named('pin_order').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class ChecklistItemsTable extends Table {
  TextColumn get id => text()();
  TextColumn get noteId => text().named('note_id').customConstraint(
      'NOT NULL REFERENCES notes_table(id) ON DELETE CASCADE')();
  TextColumn get userId => text().named('user_id')();
  TextColumn get itemText => text().named('text')();
  BoolColumn get isCompleted =>
      boolean().named('is_completed').withDefault(const Constant(false))();
  IntColumn get sortOrder =>
      integer().named('sort_order').withDefault(const Constant(0))();
  DateTimeColumn get completedAt =>
      dateTime().named('completed_at').nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

class AiSearchHistoryTable extends Table {
  TextColumn get queryHash => text().named('query_hash')();
  TextColumn get query => text()();
  TextColumn get answer => text()();
  TextColumn get citedTitlesJson =>
      text().named('cited_titles_json').withDefault(const Constant('[]'))();
  TextColumn get citedNoteIdsJson =>
      text().named('cited_note_ids_json').withDefault(const Constant('[]'))();
  DateTimeColumn get createdAt => dateTime().named('created_at')();

  @override
  Set<Column> get primaryKey => {queryHash};
}

class AiCacheTable extends Table {
  TextColumn get queryHash => text().named('query_hash')();
  TextColumn get response => text()();
  DateTimeColumn get cachedAt => dateTime().named('cached_at')();

  @override
  Set<Column> get primaryKey => {queryHash};
}

class PendingOpsTable extends Table {
  TextColumn get id => text()();
  TextColumn get opType => text().named('op_type')();
  TextColumn get recordId => text().named('record_id')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}

class NoteRemindersTable extends Table {
  TextColumn get noteId => text().named('note_id')();
  TextColumn get userId => text().named('user_id')();
  DateTimeColumn get remindAt => dateTime().named('remind_at')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  DateTimeColumn get deletedAt => dateTime().named('deleted_at').nullable()();

  @override
  Set<Column> get primaryKey => {noteId};
}

class ReminderDeviceStateTable extends Table {
  TextColumn get noteId => text().named('note_id')();
  TextColumn get reminderVersion => text().named('reminder_version')();
  IntColumn get notificationId => integer().named('notification_id')();
  DateTimeColumn get scheduledAt =>
      dateTime().named('scheduled_at').nullable()();
  DateTimeColumn get firedAt => dateTime().named('fired_at').nullable()();

  @override
  Set<Column> get primaryKey => {noteId};
}

class JotsTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().named('user_id')();
  TextColumn get jotText => text().named('text')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  DateTimeColumn get handledAt => dateTime().named('handled_at').nullable()();
  DateTimeColumn get aiProcessedAt =>
      dateTime().named('ai_processed_at').nullable()();
  TextColumn get aiSuggestionJson =>
      text().named('ai_suggestion_json').nullable()();
  TextColumn get aiSuggestionRunId =>
      text().named('ai_suggestion_run_id').nullable()();
  DateTimeColumn get reminderAt => dateTime().named('reminder_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ── FTS5 virtual table (defined via raw SQL in migration) ─────
// notes_fts: content table pointing at NotesTable
// Created in migration, not as a Drift table class.

// ── Database ──────────────────────────────────────────────────

@DriftDatabase(tables: [
  CategoriesTable,
  NotesTable,
  ChecklistItemsTable,
  AiSearchHistoryTable,
  AiCacheTable,
  PendingOpsTable,
  NoteRemindersTable,
  ReminderDeviceStateTable,
  JotsTable
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 10;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(categoriesTable, categoriesTable.color);
          }
          if (from < 3) {
            await m.createTable(pendingOpsTable);
          }
          if (from < 4) {
            await m.addColumn(notesTable, notesTable.lastOpenedAt);
          }
          if (from < 5) {
            await m.addColumn(notesTable, notesTable.isPinned);
            await m.addColumn(notesTable, notesTable.pinnedAt);
            await m.createTable(aiSearchHistoryTable);
          }
          if (from < 6) {
            await m.addColumn(notesTable, notesTable.pinOrder);
          }
          if (from < 7) {
            // aiCacheTable was created in onCreate but omitted from prior migrations.
            await m.createTable(aiCacheTable);
          }
          if (from < 8) {
            await m.addColumn(notesTable, notesTable.noteType);
            await m.createTable(checklistItemsTable);
          }
          if (from < 9) {
            await m.createTable(noteRemindersTable);
            await m.createTable(reminderDeviceStateTable);
          }
          if (from < 10) {
            await m.createTable(jotsTable);
          }
        },
        onCreate: (m) async {
          await m.createAll();
          // Create FTS5 virtual table for full-text search
          await customStatement('''
            CREATE VIRTUAL TABLE IF NOT EXISTS notes_fts
            USING fts5(
              id UNINDEXED,
              title,
              body,
              content=notes_table,
              content_rowid=rowid
            )
          ''');
          // Triggers to keep FTS index in sync
          await customStatement('''
            CREATE TRIGGER notes_ai AFTER INSERT ON notes_table BEGIN
              INSERT INTO notes_fts(rowid, id, title, body)
              VALUES (new.rowid, new.id, new.title, new.body);
            END
          ''');
          await customStatement('''
            CREATE TRIGGER notes_ad AFTER DELETE ON notes_table BEGIN
              INSERT INTO notes_fts(notes_fts, rowid, id, title, body)
              VALUES ('delete', old.rowid, old.id, old.title, old.body);
            END
          ''');
          await customStatement('''
            CREATE TRIGGER notes_au AFTER UPDATE ON notes_table BEGIN
              INSERT INTO notes_fts(notes_fts, rowid, id, title, body)
              VALUES ('delete', old.rowid, old.id, old.title, old.body);
              INSERT INTO notes_fts(rowid, id, title, body)
              VALUES (new.rowid, new.id, new.title, new.body);
            END
          ''');
        },
      );

  // ── Categories queries ──────────────────────────────────────

  Stream<List<CategoriesTableData>> watchCategories(String userId) {
    return (select(categoriesTable)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .watch();
  }

  Future<void> upsertCategory(CategoriesTableCompanion cat) async {
    await into(categoriesTable).insertOnConflictUpdate(cat);
  }

  Future<void> upsertCategories(List<CategoriesTableCompanion> cats) async {
    await batch((b) {
      for (final cat in cats) {
        b.insert(categoriesTable, cat, onConflict: DoUpdate((_) => cat));
      }
    });
  }

  Future<void> deleteCategory(String id) async {
    await (delete(categoriesTable)..where((t) => t.id.equals(id))).go();
  }

  // ── Notes queries ────────────────────────────────────────────

  Stream<List<NotesTableData>> watchNotesByCategory(
    String categoryId,
    String userId,
  ) {
    return (select(notesTable)
          ..where(
              (t) => t.categoryId.equals(categoryId) & t.userId.equals(userId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.isPinned, mode: OrderingMode.desc),
            (t) => OrderingTerm(expression: t.pinOrder, mode: OrderingMode.asc),
            (t) => OrderingTerm.desc(t.updatedAt),
          ]))
        .watch();
  }

  Stream<List<NotesTableData>> watchAllNotes(String userId) {
    return (select(notesTable)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.isPinned, mode: OrderingMode.desc),
            (t) => OrderingTerm(expression: t.pinOrder, mode: OrderingMode.asc),
            (t) => OrderingTerm.desc(t.updatedAt),
          ]))
        .watch();
  }

  Future<void> upsertNote(NotesTableCompanion note) async {
    await into(notesTable).insertOnConflictUpdate(note);
  }

  Future<void> upsertNotes(List<NotesTableCompanion> notes) async {
    await batch((b) {
      for (final note in notes) {
        b.insert(notesTable, note, onConflict: DoUpdate((_) => note));
      }
    });
  }

  Future<void> deleteNote(String id) async {
    await deleteReminder(id);
    await deleteReminderDeviceState(id);
    await deleteChecklistItemsByNoteId(id);
    await (delete(notesTable)..where((t) => t.id.equals(id))).go();
  }

  Future<void> setNoteLastOpenedAt(String id, DateTime time) async {
    await (update(notesTable)..where((t) => t.id.equals(id)))
        .write(NotesTableCompanion(lastOpenedAt: Value(time)));
  }

  Future<void> deleteNotesByCategoryId(String categoryId) async {
    final rows = await (select(notesTable)
          ..where((t) => t.categoryId.equals(categoryId)))
        .get();
    for (final row in rows) {
      await deleteChecklistItemsByNoteId(row.id);
    }
    await (delete(notesTable)..where((t) => t.categoryId.equals(categoryId)))
        .go();
  }

  Future<void> deleteAllUserNotes(String userId) async {
    await (delete(checklistItemsTable)..where((t) => t.userId.equals(userId)))
        .go();
    await (delete(notesTable)..where((t) => t.userId.equals(userId))).go();
  }

  Future<NotesTableData?> getNote(String id) {
    return (select(notesTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<NotesTableData>> getAllNotes(String userId) {
    return (select(notesTable)..where((t) => t.userId.equals(userId))).get();
  }

  Stream<NoteRemindersTableData?> watchReminderForNote(String noteId) {
    return (select(noteRemindersTable)..where((t) => t.noteId.equals(noteId)))
        .watchSingleOrNull();
  }

  Future<NoteRemindersTableData?> getReminder(String noteId) {
    return (select(noteRemindersTable)..where((t) => t.noteId.equals(noteId)))
        .getSingleOrNull();
  }

  Future<List<NoteRemindersTableData>> getAllReminders(String userId) {
    return (select(noteRemindersTable)..where((t) => t.userId.equals(userId)))
        .get();
  }

  Stream<List<NoteRemindersTableData>> watchAllReminders(String userId) {
    return (select(noteRemindersTable)..where((t) => t.userId.equals(userId)))
        .watch();
  }

  Future<void> upsertReminder(NoteRemindersTableCompanion reminder) async {
    await into(noteRemindersTable).insertOnConflictUpdate(reminder);
  }

  Future<void> upsertReminders(
      List<NoteRemindersTableCompanion> reminders) async {
    await batch((b) {
      for (final reminder in reminders) {
        b.insert(noteRemindersTable, reminder,
            onConflict: DoUpdate((_) => reminder));
      }
    });
  }

  Future<void> deleteReminder(String noteId) async {
    await (delete(noteRemindersTable)..where((t) => t.noteId.equals(noteId)))
        .go();
  }

  Future<void> upsertReminderDeviceState({
    required String noteId,
    required String reminderVersion,
    required int notificationId,
    DateTime? scheduledAt,
    DateTime? firedAt,
  }) async {
    await into(reminderDeviceStateTable).insertOnConflictUpdate(
      ReminderDeviceStateTableCompanion(
        noteId: Value(noteId),
        reminderVersion: Value(reminderVersion),
        notificationId: Value(notificationId),
        scheduledAt: Value(scheduledAt),
        firedAt: Value(firedAt),
      ),
    );
  }

  Future<ReminderDeviceStateTableData?> getReminderDeviceState(String noteId) {
    return (select(reminderDeviceStateTable)
          ..where((t) => t.noteId.equals(noteId)))
        .getSingleOrNull();
  }

  Future<void> deleteReminderDeviceState(String noteId) async {
    await (delete(reminderDeviceStateTable)
          ..where((t) => t.noteId.equals(noteId)))
        .go();
  }

  Stream<List<JotsTableData>> watchUnhandledJots(
    String userId, {
    bool newestFirst = false,
  }) {
    return (select(jotsTable)
          ..where((t) => t.userId.equals(userId) & t.handledAt.isNull())
          ..orderBy([
            (t) => newestFirst
                ? OrderingTerm.desc(t.createdAt)
                : OrderingTerm.asc(t.createdAt),
          ]))
        .watch();
  }

  Future<List<JotsTableData>> getUnhandledJots(
    String userId, {
    bool newestFirst = false,
  }) {
    return (select(jotsTable)
          ..where((t) => t.userId.equals(userId) & t.handledAt.isNull())
          ..orderBy([
            (t) => newestFirst
                ? OrderingTerm.desc(t.createdAt)
                : OrderingTerm.asc(t.createdAt),
          ]))
        .get();
  }

  Future<List<JotsTableData>> getAllJots(String userId) {
    return (select(jotsTable)..where((t) => t.userId.equals(userId))).get();
  }

  Future<JotsTableData?> getJot(String id) {
    return (select(jotsTable)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<void> upsertJot(JotsTableCompanion jot) async {
    await into(jotsTable).insertOnConflictUpdate(jot);
  }

  Future<void> upsertJots(List<JotsTableCompanion> jots) async {
    await batch((b) {
      for (final jot in jots) {
        b.insert(jotsTable, jot, onConflict: DoUpdate((_) => jot));
      }
    });
  }

  Future<void> deleteJot(String id) async {
    await (delete(jotsTable)..where((t) => t.id.equals(id))).go();
  }

  Stream<List<ChecklistItemsTableData>> watchChecklistItems(String noteId) {
    return (select(checklistItemsTable)
          ..where((t) => t.noteId.equals(noteId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.isCompleted, mode: OrderingMode.asc),
            (t) => OrderingTerm.asc(t.sortOrder),
            (t) => OrderingTerm.asc(t.createdAt),
          ]))
        .watch();
  }

  Future<List<ChecklistItemsTableData>> getChecklistItems(String noteId) {
    return (select(checklistItemsTable)
          ..where((t) => t.noteId.equals(noteId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.isCompleted, mode: OrderingMode.asc),
            (t) => OrderingTerm.asc(t.sortOrder),
            (t) => OrderingTerm.asc(t.createdAt),
          ]))
        .get();
  }

  Future<List<ChecklistItemsTableData>> getAllChecklistItems(String userId) {
    return (select(checklistItemsTable)..where((t) => t.userId.equals(userId)))
        .get();
  }

  Future<ChecklistItemsTableData?> getChecklistItem(String id) {
    return (select(checklistItemsTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> upsertChecklistItem(ChecklistItemsTableCompanion item) async {
    await into(checklistItemsTable).insertOnConflictUpdate(item);
  }

  Future<void> upsertChecklistItems(
      List<ChecklistItemsTableCompanion> items) async {
    await batch((b) {
      for (final item in items) {
        b.insert(checklistItemsTable, item, onConflict: DoUpdate((_) => item));
      }
    });
  }

  Future<void> deleteChecklistItem(String id) async {
    await (delete(checklistItemsTable)..where((t) => t.id.equals(id))).go();
  }

  Future<void> deleteChecklistItemsByNoteId(String noteId) async {
    await (delete(checklistItemsTable)..where((t) => t.noteId.equals(noteId)))
        .go();
  }

  Future<void> deleteCompletedChecklistItems(String noteId) async {
    await (delete(checklistItemsTable)
          ..where((t) => t.noteId.equals(noteId) & t.isCompleted.equals(true)))
        .go();
  }

  // ── Pending ops ───────────────────────────────────────────────

  Future<void> upsertPendingOp(
      String id, String opType, String recordId) async {
    await into(pendingOpsTable).insertOnConflictUpdate(PendingOpsTableCompanion(
      id: Value(id),
      opType: Value(opType),
      recordId: Value(recordId),
      createdAt: Value(DateTime.now().toUtc()),
    ));
  }

  Future<List<PendingOpsTableData>> getPendingOps() {
    return (select(pendingOpsTable)
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<void> deletePendingOp(String id) async {
    await (delete(pendingOpsTable)..where((t) => t.id.equals(id))).go();
  }

  Future<void> removePendingOpsForRecord(String recordId) async {
    await (delete(pendingOpsTable)..where((t) => t.recordId.equals(recordId)))
        .go();
  }

  Future<void> deleteAllPendingOps() async {
    await delete(pendingOpsTable).go();
  }

  // ── FTS5 search ──────────────────────────────────────────────

  Future<List<String>> searchNoteIds(String query, String userId) async {
    final results = await customSelect(
      '''
      SELECT n.id
      FROM notes_fts f
      JOIN notes_table n ON n.id = f.id
      WHERE notes_fts MATCH ? AND n.user_id = ?
        AND n.is_private = 0
      ORDER BY rank
      LIMIT 15
      ''',
      variables: [Variable.withString(query), Variable.withString(userId)],
      readsFrom: {notesTable},
    ).get();
    return results.map((r) => r.read<String>('id')).toList();
  }

  // ── AI search history ─────────────────────────────────────────

  Future<void> insertHistory({
    required String queryHash,
    required String query,
    required String answer,
    required List<String> citedTitles,
    required List<String> citedNoteIds,
  }) async {
    await into(aiSearchHistoryTable).insertOnConflictUpdate(
      AiSearchHistoryTableCompanion(
        queryHash: Value(queryHash),
        query: Value(query),
        answer: Value(answer),
        citedTitlesJson: Value(jsonEncode(citedTitles)),
        citedNoteIdsJson: Value(jsonEncode(citedNoteIds)),
        createdAt: Value(DateTime.now().toUtc()),
      ),
    );
    await _pruneHistory();
  }

  Future<void> _pruneHistory({int keep = 5}) async {
    final all = await (select(aiSearchHistoryTable)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    if (all.length <= keep) return;
    final toDelete = all.skip(keep).map((r) => r.queryHash).toList();
    await (delete(aiSearchHistoryTable)
          ..where((t) => t.queryHash.isIn(toDelete)))
        .go();
  }

  Stream<List<AiSearchHistoryTableData>> watchHistory() {
    return (select(aiSearchHistoryTable)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(5))
        .watch();
  }

  Future<void> clearAllHistory() async {
    await delete(aiSearchHistoryTable).go();
  }

  Future<void> removeHistoryReferencingNoteIds(List<String> ids) async {
    if (ids.isEmpty) return;
    final all = await select(aiSearchHistoryTable).get();
    final idSet = ids.toSet();
    final toDelete = <String>[];
    for (final row in all) {
      final noteIds = (jsonDecode(row.citedNoteIdsJson) as List).cast<String>();
      if (noteIds.any(idSet.contains)) toDelete.add(row.queryHash);
    }
    if (toDelete.isEmpty) return;
    await (delete(aiSearchHistoryTable)
          ..where((t) => t.queryHash.isIn(toDelete)))
        .go();
  }

  // ── AI cache ─────────────────────────────────────────────────

  Future<AiCacheTableData?> getCachedResponse(String queryHash) async {
    return (select(aiCacheTable)..where((t) => t.queryHash.equals(queryHash)))
        .getSingleOrNull();
  }

  Future<void> cacheResponse(String queryHash, String response) async {
    await into(aiCacheTable).insertOnConflictUpdate(AiCacheTableCompanion(
      queryHash: Value(queryHash),
      response: Value(response),
      cachedAt: Value(DateTime.now().toUtc()),
    ));
  }

  Future<void> evictExpiredCache(Duration ttl) async {
    final cutoff = DateTime.now().subtract(ttl);
    await (delete(aiCacheTable)
          ..where((t) => t.cachedAt.isSmallerThanValue(cutoff)))
        .go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'mindvault.db'));
    return NativeDatabase.createInBackground(file);
  });
}
