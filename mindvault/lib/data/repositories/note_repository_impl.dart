import '../../core/utils/id_generator.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../remote/supabase/supabase_notes_datasource.dart';
import '../local/database/app_database.dart';
import '../models/note_model.dart';
import '../../services/encryption_service.dart';
import '../../services/analytics_service.dart';
import '../../services/error_log_service.dart';
import 'package:encrypt/encrypt.dart';
import 'package:drift/drift.dart';

class NoteRepositoryImpl implements NoteRepository {
  final SupabaseNotesDatasource _remote;
  final AppDatabase _local;
  final EncryptionService _encryption;
  final Key _aesKey;
  final String _userId;
  final AnalyticsService? _analytics;
  final ErrorLogger _errorLogger;

  NoteRepositoryImpl({
    required SupabaseNotesDatasource remote,
    required AppDatabase local,
    required EncryptionService encryption,
    required Key aesKey,
    required String userId,
    AnalyticsService? analytics,
    ErrorLogger errorLogger = const NoopErrorLogger(),
  })  : _remote = remote,
        _local = local,
        _encryption = encryption,
        _aesKey = aesKey,
        _userId = userId,
        _analytics = analytics,
        _errorLogger = errorLogger;

  // ── Realtime sync ─────────────────────────────────────────────

  void startSync() {
    _syncAllNotes();
    _remote.subscribeToNotes((isDelete, record) async {
      try {
        if (isDelete) {
          final id = record['id'] as String?;
          if (id != null) {
            await _local.deleteNote(id);
            await _local.removeHistoryReferencingNoteIds([id]);
          }
        } else {
          final model = NoteModel.fromJson(record);
          final note = _decryptModel(model);
          await _local.upsertNote(_noteToCompanion(note));
        }
      } catch (e) {
        _errorLogger.report(source: 'realtime_sync', message: e.toString());
      }
    });
  }

  void stopSync() => _remote.unsubscribeNotes();

  // ── Encryption helpers ────────────────────────────────────────

  String _enc(String text) => _encryption.encrypt(text, _aesKey);
  String _dec(String cipher) => _encryption.decrypt(cipher, _aesKey);

  Note _decryptModel(NoteModel m) {
    return Note(
      id: m.id,
      userId: m.userId,
      categoryId: m.categoryId,
      title: _dec(m.title),
      body: _dec(m.body),
      isPrivate: m.isPrivate,
      lastUsedAt: DateTime.parse(m.lastUsedAt),
      createdAt: DateTime.parse(m.createdAt),
      updatedAt: DateTime.parse(m.updatedAt),
      isPinned: m.isPinned,
      pinnedAt: m.pinnedAt != null ? DateTime.parse(m.pinnedAt!) : null,
      pinOrder: m.pinOrder,
    );
  }

  // ── Watch streams ─────────────────────────────────────────────

  @override
  Stream<List<Note>> watchNotesByCategory(String categoryId) {
    return _local.watchNotesByCategory(categoryId).map(
          (rows) => rows.map(_rowToNote).toList(),
        );
  }

  @override
  Stream<List<Note>> watchAllNotes() {
    return _local.watchAllNotes(_userId).map(
          (rows) => rows.map(_rowToNote).toList(),
        );
  }

  Note _rowToNote(NotesTableData row) => Note(
        id: row.id,
        userId: row.userId,
        categoryId: row.categoryId,
        title: row.title,
        body: row.body,
        isPrivate: row.isPrivate,
        lastUsedAt: row.lastUsedAt,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        lastOpenedAt: row.lastOpenedAt,
        isPinned: row.isPinned,
        pinnedAt: row.pinnedAt,
        pinOrder: row.pinOrder,
      );

  // ── Sync helpers ──────────────────────────────────────────────

  Future<void> _syncAllNotes() async {
    try {
      final models = await _remote.fetchAllNotes();
      await _upsertDecryptedModels(models);

      // Reconcile deletions: remove Drift notes absent from Supabase,
      // but preserve notes with a pending create op (not yet pushed).
      final remoteIds = models.map((m) => m.id).toSet();
      final pendingOps = await _local.getPendingOps();
      final pendingCreateIds = pendingOps
          .where((o) => o.opType == 'create_note')
          .map((o) => o.recordId)
          .toSet();
      final localNotes = await _local.getAllNotes(_userId);
      for (final row in localNotes) {
        if (!remoteIds.contains(row.id) && !pendingCreateIds.contains(row.id)) {
          await _local.deleteNote(row.id);
        }
      }
    } catch (e) {
      _errorLogger.report(source: 'sync_all_notes', message: e.toString());
    }
  }

  Future<void> _upsertDecryptedModels(List<NoteModel> models) async {
    final companions = <NotesTableCompanion>[];
    for (final m in models) {
      try {
        companions.add(_noteToCompanion(_decryptModel(m)));
      } catch (_) {
        // Note was encrypted with a different key (e.g. after key rotation).
        // Skip it rather than aborting the entire batch.
      }
    }
    if (companions.isNotEmpty) await _local.upsertNotes(companions);
  }

  NotesTableCompanion _noteToCompanion(Note n) => NotesTableCompanion(
        id: Value(n.id),
        userId: Value(n.userId),
        categoryId: Value(n.categoryId),
        title: Value(n.title),
        body: Value(n.body),
        isPrivate: Value(n.isPrivate),
        lastUsedAt: Value(n.lastUsedAt),
        createdAt: Value(n.createdAt),
        updatedAt: Value(n.updatedAt),
        isPinned: Value(n.isPinned),
        pinnedAt: Value(n.pinnedAt),
        pinOrder: Value(n.pinOrder),
        // lastOpenedAt intentionally absent — preserved on upsert conflict
      );

  // ── CRUD ──────────────────────────────────────────────────────

  @override
  Future<Note?> getNoteById(String id) async {
    final row = await _local.getNote(id);
    return row == null ? null : _rowToNote(row);
  }

  @override
  Future<Note> createNote({
    required String categoryId,
    required String title,
    required String body,
    required bool isPrivate,
  }) async {
    final id = generateId();
    final now = DateTime.now().toUtc();
    final note = Note(
      id: id,
      userId: _userId,
      categoryId: categoryId,
      title: title,
      body: body,
      isPrivate: isPrivate,
      lastUsedAt: now,
      createdAt: now,
      updatedAt: now,
    );
    await _local.upsertNote(_noteToCompanion(note));
    _analytics?.track('note_created');

    try {
      final data = {
        'id': id,
        'category_id': categoryId,
        'title': _enc(title),
        'body': _enc(body),
        'is_private': isPrivate,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'last_used_at': now.toIso8601String(),
      };
      final model = await _remote.insertNote(data);
      final synced = _decryptModel(model);
      await _local.upsertNote(_noteToCompanion(synced));
      return synced;
    } catch (_) {
      await _local.upsertPendingOp(id, 'create_note', id);
      return note;
    }
  }

  @override
  Future<Note> updateNote({
    required String id,
    String? title,
    String? body,
    bool? isPrivate,
    String? categoryId,
  }) async {
    final existing = await _local.getNote(id);
    final now = DateTime.now().toUtc();
    final updated = Note(
      id: id,
      userId: _userId,
      categoryId: categoryId ?? existing?.categoryId ?? '',
      title: title ?? existing?.title ?? '',
      body: body ?? existing?.body ?? '',
      isPrivate: isPrivate ?? existing?.isPrivate ?? false,
      lastUsedAt: now,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      isPinned: existing?.isPinned ?? false,
      pinnedAt: existing?.pinnedAt,
      pinOrder: existing?.pinOrder,
    );
    await _local.upsertNote(_noteToCompanion(updated));

    try {
      final data = <String, dynamic>{};
      if (title != null) data['title'] = _enc(title);
      if (body != null) data['body'] = _enc(body);
      if (isPrivate != null) data['is_private'] = isPrivate;
      if (categoryId != null) data['category_id'] = categoryId;
      final model = await _remote.updateNote(id, data);
      final synced = _decryptModel(model);
      await _local.upsertNote(_noteToCompanion(synced));
      // Remove any stale pending op since we just synced
      await _local.deletePendingOp(id);
      return synced;
    } catch (_) {
      await _local.upsertPendingOp(id, 'update_note', id);
      return updated;
    }
  }

  @override
  Future<void> deleteNote(String id) async {
    await _local.deleteNote(id);
    _analytics?.track('note_deleted');
    await _local.removePendingOpsForRecord(id);
    await _local.removeHistoryReferencingNoteIds([id]);
    try {
      await _remote.deleteNote(id);
    } catch (_) {
      await _local.upsertPendingOp('del_$id', 'delete_note', id);
    }
  }

  // ── Pending ops sync ──────────────────────────────────────────

  @override
  Future<void> syncPendingOps() async {
    final ops = await _local.getPendingOps();
    final noteOps = ops.where((o) =>
        o.opType == 'create_note' ||
        o.opType == 'update_note' ||
        o.opType == 'delete_note');

    for (final op in noteOps) {
      try {
        if (op.opType == 'delete_note') {
          await _remote.deleteNote(op.recordId);
          // Re-delete locally: Realtime may have re-inserted the note on reconnect.
          await _local.deleteNote(op.recordId);
        } else {
          final row = await _local.getNote(op.recordId);
          if (row == null) {
            // Note was deleted locally after the pending op was queued; nothing to push.
            await _local.deletePendingOp(op.id);
            continue;
          }
          final note = _rowToNote(row);

          // Last-write-wins: skip if the remote already has a newer version.
          // This can happen when another device edits the same note while this
          // device was offline. _syncAllNotes() at the end will pull the winner.
          if (op.opType == 'update_note') {
            try {
              final remote = await _remote.fetchNoteById(note.id);
              if (remote != null &&
                  DateTime.parse(remote.updatedAt).isAfter(note.updatedAt)) {
                await _local.deletePendingOp(op.id);
                continue;
              }
            } catch (_) {
              // Can't verify; proceed with upsert.
            }
          }

          await _remote.upsertNote({
            'id': note.id,
            'category_id': note.categoryId,
            'title': _enc(note.title),
            'body': _enc(note.body),
            'is_private': note.isPrivate,
            'created_at': note.createdAt.toUtc().toIso8601String(),
            'updated_at': note.updatedAt.toUtc().toIso8601String(),
            'last_used_at': note.lastUsedAt.toUtc().toIso8601String(),
            'is_pinned': note.isPinned,
            'pinned_at': note.pinnedAt?.toUtc().toIso8601String(),
            'pin_order': note.pinOrder,
          });
        }
        await _local.deletePendingOp(op.id);
      } catch (_) {
        // Don't break — a single op failure (e.g. transient error) must not
        // prevent other ops from being attempted.
      }
    }

    await _syncAllNotes();
  }

  @override
  Future<void> markNoteOpened(String id) async {
    await _local.setNoteLastOpenedAt(id, DateTime.now().toUtc());
  }

  @override
  Future<List<Note>> searchNotes(String query) async {
    final ids = await _local.searchNoteIds(query, _userId);
    if (ids.isEmpty) return [];
    final rows = await (_local.select(_local.notesTable)
          ..where((t) => t.id.isIn(ids)))
        .get();
    return rows.map(_rowToNote).toList();
  }

  @override
  Future<void> setNotePinned({required String id, required bool isPinned}) async {
    final existing = await _local.getNote(id);
    if (existing == null) return;

    int? newPinOrder;
    DateTime? newPinnedAt;

    if (isPinned) {
      final pinnedRows = await (_local.select(_local.notesTable)
            ..where((t) => t.userId.equals(_userId) & t.isPinned.equals(true)))
          .get();
      final maxOrder = pinnedRows.isEmpty
          ? -1
          : pinnedRows
              .map((r) => r.pinOrder ?? -1)
              .reduce((a, b) => a > b ? a : b);
      newPinOrder = maxOrder + 1;
      newPinnedAt = DateTime.now().toUtc();
    }

    final pinNow = DateTime.now().toUtc();
    await _local.upsertNote(NotesTableCompanion(
      id: Value(id),
      userId: Value(existing.userId),
      categoryId: Value(existing.categoryId),
      title: Value(existing.title),
      body: Value(existing.body),
      isPrivate: Value(existing.isPrivate),
      lastUsedAt: Value(existing.lastUsedAt),
      createdAt: Value(existing.createdAt),
      updatedAt: Value(pinNow),
      isPinned: Value(isPinned),
      pinnedAt: Value(isPinned ? newPinnedAt : null),
      pinOrder: Value(isPinned ? newPinOrder : null),
    ));

    try {
      await _remote.updateNote(id, {
        'is_pinned': isPinned,
        'pinned_at': (isPinned ? newPinnedAt : null)?.toIso8601String(),
        'pin_order': isPinned ? newPinOrder : null,
      });
      await _local.deletePendingOp(id);
    } catch (_) {
      await _local.upsertPendingOp(id, 'update_note', id);
    }
  }

  @override
  Future<void> reorderPinnedNotes(List<String> orderedIds) async {
    final reorderNow = DateTime.now().toUtc();
    final rows = await (_local.select(_local.notesTable)
          ..where((t) => t.id.isIn(orderedIds)))
        .get();
    final rowById = {for (final r in rows) r.id: r};
    final companions = <NotesTableCompanion>[];
    for (var i = 0; i < orderedIds.length; i++) {
      final row = rowById[orderedIds[i]];
      if (row == null) continue;
      companions.add(NotesTableCompanion(
        id: Value(row.id),
        userId: Value(row.userId),
        categoryId: Value(row.categoryId),
        title: Value(row.title),
        body: Value(row.body),
        isPrivate: Value(row.isPrivate),
        lastUsedAt: Value(row.lastUsedAt),
        createdAt: Value(row.createdAt),
        updatedAt: Value(reorderNow),
        isPinned: const Value(true),
        pinnedAt: Value(row.pinnedAt),
        pinOrder: Value(i),
      ));
    }
    // Single batch write → one stream emission instead of N, eliminating
    // the flicker caused by intermediate states triggering a UI rebuild.
    if (companions.isNotEmpty) await _local.upsertNotes(companions);

    final updates = orderedIds
        .asMap()
        .entries
        .map((e) => {'id': e.value, 'pin_order': e.key})
        .toList();
    try {
      await _remote.updatePinOrders(updates);
    } catch (_) {
      for (final id in orderedIds) {
        await _local.upsertPendingOp(id, 'update_note', id);
      }
    }
  }
}
