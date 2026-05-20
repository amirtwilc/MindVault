import 'dart:async';

import 'package:drift/drift.dart';
import 'package:encrypt/encrypt.dart';

import '../../core/utils/id_generator.dart';
import '../../domain/entities/checklist_item.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../../services/analytics_service.dart';
import '../../services/encryption_service.dart';
import '../../services/error_log_service.dart';
import '../local/database/app_database.dart';
import '../local/database/note_mappers.dart';
import '../models/checklist_item_model.dart';
import '../models/note_model.dart';
import '../remote/supabase/supabase_notes_datasource.dart';

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

  void startSync() {
    _syncAllNotes();
    _syncAllChecklistItems();
    _remote.subscribeToNotes((isDelete, record) async {
      try {
        if (isDelete) {
          final id = record['id'] as String?;
          if (id != null && !await _hasPendingNoteMutation(id)) {
            await _local.deleteNote(id);
            await _local.removeHistoryReferencingNoteIds([id]);
          }
        } else {
          final id = record['id'] as String?;
          if (id != null && await _hasPendingNoteMutation(id)) return;
          final note = _decryptModel(NoteModel.fromJson(record));
          await _local.upsertNote(_noteToCompanion(note));
        }
      } catch (e) {
        _errorLogger.report(source: 'realtime_sync', message: e.toString());
      }
    });
    _remote.subscribeToChecklistItems((isDelete, record) async {
      try {
        if (isDelete) {
          final id = record['id'] as String?;
          if (id != null && !await _hasPendingChecklistMutation(id)) {
            await _local.deleteChecklistItem(id);
          }
        } else {
          final id = record['id'] as String?;
          if (id != null && await _hasPendingChecklistMutation(id)) return;
          final item =
              _decryptChecklistModel(ChecklistItemModel.fromJson(record));
          await _local.upsertChecklistItem(_checklistItemToCompanion(item));
          await _refreshChecklistBody(item.noteId);
        }
      } catch (e) {
        _errorLogger.report(
            source: 'realtime_checklist_sync', message: e.toString());
      }
    });
  }

  void stopSync() => _remote.unsubscribeNotes();

  String _enc(String text) => _encryption.encrypt(text, _aesKey);
  String _dec(String cipher) => _encryption.decrypt(cipher, _aesKey);

  Note _decryptModel(NoteModel m) => Note(
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
        noteType: NoteType.fromStorage(m.noteType),
      );

  ChecklistItem _decryptChecklistModel(ChecklistItemModel m) =>
      m.toEntity(decryptedText: _dec(m.text));

  @override
  Stream<List<Note>> watchNotesByCategory(String categoryId) {
    return _local.watchNotesByCategory(categoryId, _userId).map(
          (rows) => rows.map(rowToNote).toList(),
        );
  }

  @override
  Stream<List<Note>> watchAllNotes() {
    return _local.watchAllNotes(_userId).map(
          (rows) => rows.map(rowToNote).toList(),
        );
  }

  @override
  Stream<List<ChecklistItem>> watchChecklistItems(String noteId) {
    return _local.watchChecklistItems(noteId).map(
          (rows) => rows.map(rowToChecklistItem).toList(),
        );
  }

  Future<bool> _hasPendingNoteMutation(String noteId) async {
    final ops = await _local.getPendingOps();
    return ops.any((op) =>
        op.recordId == noteId &&
        (op.opType == 'create_note' || op.opType == 'update_note'));
  }

  Future<bool> _hasPendingChecklistMutation(String itemId) async {
    final ops = await _local.getPendingOps();
    return ops.any((op) =>
        op.recordId == itemId &&
        (op.opType == 'create_checklist_item' ||
            op.opType == 'update_checklist_item' ||
            op.opType == 'delete_checklist_item'));
  }

  Future<void> _syncAllNotes() async {
    try {
      final models = await _remote.fetchAllNotes();
      final filtered = <NoteModel>[];
      for (final model in models) {
        if (!await _hasPendingNoteMutation(model.id)) {
          filtered.add(model);
        }
      }
      await _upsertDecryptedModels(filtered);

      final remoteIds = filtered.map((m) => m.id).toSet();
      final pendingOps = await _local.getPendingOps();
      final pendingCreateIds = pendingOps
          .where((o) => o.opType == 'create_note' || o.opType == 'update_note')
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

  Future<void> _syncAllChecklistItems() async {
    try {
      final models = await _remote.fetchAllChecklistItems();
      final companions = <ChecklistItemsTableCompanion>[];
      for (final model in models) {
        if (await _hasPendingChecklistMutation(model.id)) continue;
        try {
          companions
              .add(_checklistItemToCompanion(_decryptChecklistModel(model)));
        } catch (_) {}
      }
      if (companions.isNotEmpty) await _local.upsertChecklistItems(companions);

      final remoteIds = models.map((m) => m.id).toSet();
      final localItems = await _local.getAllChecklistItems(_userId);
      for (final row in localItems) {
        if (!remoteIds.contains(row.id) &&
            !await _hasPendingChecklistMutation(row.id)) {
          await _local.deleteChecklistItem(row.id);
          await _refreshChecklistBody(row.noteId);
        }
      }
    } catch (e) {
      _errorLogger.report(
          source: 'sync_all_checklist_items', message: e.toString());
    }
  }

  Future<void> _upsertDecryptedModels(List<NoteModel> models) async {
    final companions = <NotesTableCompanion>[];
    for (final m in models) {
      try {
        companions.add(_noteToCompanion(_decryptModel(m)));
      } catch (_) {}
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
        noteType: Value(n.noteType.storageValue),
        isPinned: Value(n.isPinned),
        pinnedAt: Value(n.pinnedAt),
        pinOrder: Value(n.pinOrder),
      );

  ChecklistItemsTableCompanion _checklistItemToCompanion(ChecklistItem i) =>
      ChecklistItemsTableCompanion(
        id: Value(i.id),
        noteId: Value(i.noteId),
        userId: Value(i.userId),
        itemText: Value(i.text),
        isCompleted: Value(i.isCompleted),
        sortOrder: Value(i.sortOrder),
        completedAt: Value(i.completedAt),
        createdAt: Value(i.createdAt),
        updatedAt: Value(i.updatedAt),
      );

  Map<String, dynamic> _checklistItemPayload(ChecklistItem item) => {
        'id': item.id,
        'note_id': item.noteId,
        'text': _enc(item.text),
        'is_completed': item.isCompleted,
        'sort_order': item.sortOrder,
        'completed_at': item.completedAt?.toUtc().toIso8601String(),
        'created_at': item.createdAt.toUtc().toIso8601String(),
        'updated_at': item.updatedAt.toUtc().toIso8601String(),
      };

  Future<void> _refreshChecklistBody(String noteId) async {
    final row = await _local.getNote(noteId);
    if (row == null ||
        NoteType.fromStorage(row.noteType) != NoteType.checklist) {
      return;
    }
    final items = await _local.getChecklistItems(noteId);
    final body = items
        .map((i) => i.itemText.trim())
        .where((text) => text.isNotEmpty)
        .join('\n');
    final now = DateTime.now().toUtc();
    await _local.upsertNote(_noteToCompanion(rowToNote(row).copyWith(
      body: body,
      updatedAt: now,
      lastUsedAt: now,
    )));
  }

  Future<void> _syncChecklistBodyNote(String noteId) async {
    final row = await _local.getNote(noteId);
    if (row == null) return;
    try {
      await _remote.updateNote(noteId, {
        'body': _enc(row.body),
        'note_type': NoteType.checklist.storageValue,
      });
      await _local.deletePendingOp(noteId);
    } catch (_) {
      await _local.upsertPendingOp(noteId, 'update_note', noteId);
    }
  }

  @override
  Future<Note?> getNoteById(String id) async {
    final row = await _local.getNote(id);
    return row == null ? null : rowToNote(row);
  }

  @override
  Future<Note> createNote({
    required String categoryId,
    required String title,
    required String body,
    required bool isPrivate,
    NoteType noteType = NoteType.text,
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
      noteType: noteType,
    );
    await _local.upsertNote(_noteToCompanion(note));
    _analytics?.track('note_created');

    try {
      final model = await _remote.insertNote({
        'id': id,
        'category_id': categoryId,
        'title': _enc(title),
        'body': _enc(body),
        'is_private': isPrivate,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'last_used_at': now.toIso8601String(),
        'note_type': noteType.storageValue,
      });
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
    NoteType? noteType,
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
      noteType: noteType ?? NoteType.fromStorage(existing?.noteType ?? 'text'),
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
      if (noteType != null) data['note_type'] = noteType.storageValue;
      final model = await _remote.updateNote(id, data);
      final synced = _decryptModel(model);
      await _local.upsertNote(_noteToCompanion(synced));
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

  @override
  Future<void> syncPendingOps() async {
    final ops = await _local.getPendingOps();
    for (final op in ops) {
      try {
        if (op.opType == 'delete_note') {
          await _remote.deleteNote(op.recordId);
          await _local.deleteNote(op.recordId);
        } else if (op.opType == 'create_note' || op.opType == 'update_note') {
          final row = await _local.getNote(op.recordId);
          if (row == null) {
            await _local.deletePendingOp(op.id);
            continue;
          }
          final note = rowToNote(row);
          if (op.opType == 'update_note') {
            try {
              final remote = await _remote.fetchNoteById(note.id);
              if (remote != null &&
                  DateTime.parse(remote.updatedAt).isAfter(note.updatedAt)) {
                await _local.deletePendingOp(op.id);
                continue;
              }
            } catch (_) {}
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
            'note_type': note.noteType.storageValue,
          });
        } else if (op.opType == 'delete_checklist_item') {
          await _remote.deleteChecklistItem(op.recordId);
          await _local.deleteChecklistItem(op.recordId);
        } else if (op.opType == 'create_checklist_item' ||
            op.opType == 'update_checklist_item') {
          final row = await _local.getChecklistItem(op.recordId);
          if (row == null) {
            await _local.deletePendingOp(op.id);
            continue;
          }
          await _remote.upsertChecklistItem(
              _checklistItemPayload(rowToChecklistItem(row)));
        }
        await _local.deletePendingOp(op.id);
      } catch (_) {}
    }
    await _syncAllNotes();
    await _syncAllChecklistItems();
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
    return rows.map(rowToNote).toList();
  }

  @override
  Future<void> setNotePinned(
      {required String id, required bool isPinned}) async {
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
    await _local.upsertNote(_noteToCompanion(rowToNote(existing).copyWith(
      updatedAt: pinNow,
      isPinned: isPinned,
      pinnedAt: isPinned ? newPinnedAt : null,
      pinOrder: isPinned ? newPinOrder : null,
    )));

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
      companions.add(_noteToCompanion(rowToNote(row).copyWith(
        updatedAt: reorderNow,
        isPinned: true,
        pinOrder: i,
      )));
    }
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

  @override
  Future<List<ChecklistItem>> getChecklistItems(String noteId) async {
    final rows = await _local.getChecklistItems(noteId);
    return rows.map(rowToChecklistItem).toList();
  }

  @override
  Future<void> convertNoteType({
    required String noteId,
    required NoteType noteType,
  }) async {
    final row = await _local.getNote(noteId);
    if (row == null) return;
    final current = NoteType.fromStorage(row.noteType);
    if (current == noteType) return;

    if (noteType == NoteType.checklist) {
      final lines = row.body
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
      await updateNote(id: noteId, body: lines.join('\n'), noteType: noteType);
      await replaceChecklistItems(noteId: noteId, texts: lines);
    } else {
      final items = await _local.getChecklistItems(noteId);
      final body = items
          .map((item) => item.itemText.trim())
          .where((text) => text.isNotEmpty)
          .join('\n');
      await _local.deleteChecklistItemsByNoteId(noteId);
      await updateNote(id: noteId, body: body, noteType: noteType);
      try {
        await _remote.deleteChecklistItemsByNoteId(noteId);
      } catch (_) {
        for (final item in items) {
          await _local.upsertPendingOp(
              'del_checklist_${item.id}', 'delete_checklist_item', item.id);
        }
      }
    }
  }

  @override
  Future<List<ChecklistItem>> replaceChecklistItems({
    required String noteId,
    required List<String> texts,
    List<bool>? completionStates,
    List<String?>? rowIds,
  }) async {
    final existing = await _local.getChecklistItems(noteId);
    final existingById = {for (final item in existing) item.id: item};
    final cleanTexts = <String>[];
    final cleanStates = <bool>[];
    final cleanRowIds = <String?>[];
    for (var i = 0; i < texts.length; i++) {
      final trimmed = texts[i].trim();
      if (trimmed.isEmpty) continue;
      cleanTexts.add(trimmed);
      cleanStates.add(
        completionStates != null && i < completionStates.length
            ? completionStates[i]
            : false,
      );
      cleanRowIds.add(rowIds != null && i < rowIds.length ? rowIds[i] : null);
    }
    final now = DateTime.now().toUtc();
    final items = <ChecklistItem>[];
    for (var i = 0; i < cleanTexts.length; i++) {
      final old = cleanRowIds[i] != null ? existingById[cleanRowIds[i]!] : null;
      final resolvedCompleted = old?.isCompleted ?? cleanStates[i];
      items.add(ChecklistItem(
        id: old?.id ?? generateId(),
        noteId: noteId,
        userId: _userId,
        text: cleanTexts[i],
        isCompleted: resolvedCompleted,
        sortOrder: i,
        completedAt: resolvedCompleted ? old?.completedAt ?? now : null,
        createdAt: old?.createdAt ?? now,
        updatedAt: now,
      ));
    }

    final keepIds = items.map((i) => i.id).toSet();
    final removed = existing.where((i) => !keepIds.contains(i.id)).toList();
    await _local
        .upsertChecklistItems(items.map(_checklistItemToCompanion).toList());
    for (final item in removed) {
      await _local.deleteChecklistItem(item.id);
    }
    await updateNote(
      id: noteId,
      body: cleanTexts.join('\n'),
      noteType: NoteType.checklist,
    );

    try {
      await _remote
          .upsertChecklistItems(items.map(_checklistItemPayload).toList());
      for (final item in removed) {
        await _remote.deleteChecklistItem(item.id);
      }
    } catch (_) {
      for (final item in items) {
        await _local.upsertPendingOp(item.id, 'update_checklist_item', item.id);
      }
      for (final item in removed) {
        await _local.upsertPendingOp(
            'del_checklist_${item.id}', 'delete_checklist_item', item.id);
      }
    }
    return items;
  }

  @override
  Future<void> toggleChecklistItem({
    required String id,
    required bool isCompleted,
  }) async {
    final row = await _local.getChecklistItem(id);
    if (row == null) return;
    final now = DateTime.now().toUtc();
    final siblings = await _local.getChecklistItems(row.noteId);
    final sameSectionCount = siblings
        .where((i) => i.id != id && i.isCompleted == isCompleted)
        .length;
    final item = rowToChecklistItem(row).copyWith(
      isCompleted: isCompleted,
      completedAt: isCompleted ? now : null,
      sortOrder: isCompleted ? 0 : sameSectionCount,
      updatedAt: now,
    );
    await _local.upsertChecklistItem(_checklistItemToCompanion(item));
    await _refreshChecklistBody(item.noteId);
    unawaited(_pushChecklistToggle(item));
  }

  Future<void> _pushChecklistToggle(ChecklistItem item) async {
    await _syncChecklistBodyNote(item.noteId);
    try {
      await _remote.upsertChecklistItem(_checklistItemPayload(item));
    } catch (_) {
      await _local.upsertPendingOp(item.id, 'update_checklist_item', item.id);
    }
  }

  @override
  Future<void> reorderChecklistItems({
    required String noteId,
    required List<String> orderedIds,
  }) async {
    final rows = await _local.getChecklistItems(noteId);
    final byId = {for (final row in rows) row.id: row};
    final now = DateTime.now().toUtc();
    final items = <ChecklistItem>[];
    for (var i = 0; i < orderedIds.length; i++) {
      final row = byId[orderedIds[i]];
      if (row == null) continue;
      items.add(rowToChecklistItem(row).copyWith(sortOrder: i, updatedAt: now));
    }
    await _local
        .upsertChecklistItems(items.map(_checklistItemToCompanion).toList());
    await _refreshChecklistBody(noteId);
    await _syncChecklistBodyNote(noteId);
    try {
      await _remote
          .upsertChecklistItems(items.map(_checklistItemPayload).toList());
    } catch (_) {
      for (final item in items) {
        await _local.upsertPendingOp(item.id, 'update_checklist_item', item.id);
      }
    }
  }

  @override
  Future<void> deleteCompletedChecklistItems(String noteId) async {
    final items = await _local.getChecklistItems(noteId);
    final completed = items.where((item) => item.isCompleted).toList();
    await _local.deleteCompletedChecklistItems(noteId);
    await _refreshChecklistBody(noteId);
    await _syncChecklistBodyNote(noteId);
    for (final item in completed) {
      try {
        await _remote.deleteChecklistItem(item.id);
      } catch (_) {
        await _local.upsertPendingOp(
            'del_checklist_${item.id}', 'delete_checklist_item', item.id);
      }
    }
  }
}
