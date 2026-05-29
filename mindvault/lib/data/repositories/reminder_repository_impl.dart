import 'package:drift/drift.dart';

import '../../domain/entities/note_reminder.dart';
import '../../domain/repositories/reminder_repository.dart';
import '../../services/error_log_service.dart';
import '../local/database/app_database.dart';
import '../local/database/note_mappers.dart';
import '../models/note_reminder_model.dart';
import '../remote/supabase/supabase_notes_datasource.dart';

class ReminderRepositoryImpl implements ReminderRepository {
  final SupabaseNotesDatasource _remote;
  final AppDatabase _local;
  final String _userId;
  final ErrorLogger _errorLogger;

  ReminderRepositoryImpl({
    required SupabaseNotesDatasource remote,
    required AppDatabase local,
    required String userId,
    ErrorLogger errorLogger = const NoopErrorLogger(),
  })  : _remote = remote,
        _local = local,
        _userId = userId,
        _errorLogger = errorLogger;

  void startSync() {
    syncAllReminders();
    _remote.subscribeToReminders((isDelete, record) async {
      try {
        final noteId = record['note_id'] as String?;
        if (noteId == null) return;
        if (await _hasPendingReminderMutation(noteId)) return;
        if (isDelete) {
          await _local.deleteReminder(noteId);
          await _local.deleteReminderDeviceState(noteId);
        } else {
          final reminder = NoteReminderModel.fromJson(record).toEntity();
          await _mergeRemoteReminder(reminder);
        }
      } catch (e) {
        _errorLogger.report(
            source: 'realtime_reminders', message: e.toString());
      }
    });
  }

  void stopSync() => _remote.unsubscribeReminders();

  bool isActive(NoteReminder reminder, DateTime now) =>
      reminder.isActiveAt(now);

  @override
  Stream<NoteReminder?> watchReminderForNote(String noteId) {
    final now = DateTime.now().toUtc();
    return _local.watchReminderForNote(noteId).map((row) {
      if (row == null) return null;
      final reminder = rowToReminder(row);
      return isActive(reminder, now) ? reminder : null;
    });
  }

  @override
  Future<NoteReminder?> getReminderForNote(String noteId) async {
    final row = await _local.getReminder(noteId);
    if (row == null) return null;
    final reminder = rowToReminder(row);
    return isActive(reminder, DateTime.now().toUtc()) ? reminder : null;
  }

  @override
  Future<List<NoteReminder>> getActiveReminders() async {
    final now = DateTime.now().toUtc();
    final rows = await _local.getAllReminders(_userId);
    return rows.map(rowToReminder).where((r) => isActive(r, now)).toList();
  }

  @override
  Future<NoteReminder> setReminder(String noteId, DateTime remindAtUtc) async {
    final now = DateTime.now().toUtc();
    final existing = await _local.getReminder(noteId);
    final reminder = NoteReminder(
      noteId: noteId,
      userId: _userId,
      remindAt: remindAtUtc.toUtc(),
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    await _local.upsertReminder(_reminderToCompanion(reminder));

    try {
      final synced =
          (await _remote.upsertReminder(_payload(reminder))).toEntity();
      await _local.upsertReminder(_reminderToCompanion(synced));
      await _local.deletePendingOp(_pendingId(noteId));
      return synced;
    } catch (e) {
      _errorLogger.report(
        source: 'upsert_reminder_remote',
        message: e.toString(),
        context: {'memory_id': noteId},
      );
      await _local.upsertPendingOp(
          _pendingId(noteId), 'upsert_reminder', noteId);
      return reminder;
    }
  }

  @override
  Future<void> removeReminder(String noteId) async {
    final row = await _local.getReminder(noteId);
    if (row == null) return;
    final now = DateTime.now().toUtc();
    final reminder = rowToReminder(row).copyWith(
      updatedAt: now,
      deletedAt: now,
    );
    await _local.upsertReminder(_reminderToCompanion(reminder));
    await _local.deleteReminderDeviceState(noteId);

    try {
      await _remote.upsertReminder(_payload(reminder));
      await _local.deletePendingOp(_pendingId(noteId));
    } catch (e) {
      _errorLogger.report(
        source: 'delete_reminder_remote',
        message: e.toString(),
        context: {'memory_id': noteId},
      );
      await _local.upsertPendingOp(
          _pendingId(noteId), 'delete_reminder', noteId);
    }
  }

  @override
  Future<void> syncPendingOps() async {
    final ops = await _local.getPendingOps();
    for (final op in ops.where((o) =>
        o.opType == 'upsert_reminder' || o.opType == 'delete_reminder')) {
      try {
        final row = await _local.getReminder(op.recordId);
        if (row == null) {
          await _local.deletePendingOp(op.id);
          continue;
        }
        await _remote.upsertReminder(_payload(rowToReminder(row)));
        await _local.deletePendingOp(op.id);
      } catch (e) {
        _errorLogger.report(
          source: 'sync_pending_reminder_op',
          message: e.toString(),
          context: {'memory_id': op.recordId, 'op_type': op.opType},
        );
      }
    }
    await syncAllReminders();
  }

  @override
  Future<void> syncAllReminders() async {
    try {
      final models = await _remote.fetchAllReminders();
      for (final model in models) {
        try {
          if (!await _hasPendingReminderMutation(model.noteId)) {
            await _mergeRemoteReminder(model.toEntity());
          }
        } catch (e) {
          _errorLogger.report(
            source: 'sync_all_reminders_row',
            message: e.toString(),
          );
        }
      }
    } catch (e) {
      _errorLogger.report(source: 'sync_all_reminders', message: e.toString());
    }
  }

  @override
  Future<void> cleanupExpiredReminders(DateTime now) async {
    final rows = await _local.getAllReminders(_userId);
    for (final row in rows) {
      final reminder = rowToReminder(row);
      if (reminder.isDeleted) {
        continue;
      }
      if (!reminder.remindAt.isAfter(now.toUtc())) {
        await removeReminder(reminder.noteId);
      }
    }
  }

  Future<bool> _hasPendingReminderMutation(String noteId) async {
    final ops = await _local.getPendingOps();
    return ops.any((op) =>
        op.recordId == noteId &&
        (op.opType == 'upsert_reminder' || op.opType == 'delete_reminder'));
  }

  Future<void> _mergeRemoteReminder(NoteReminder remote) async {
    final local = await _local.getReminder(remote.noteId);
    if (local != null && local.updatedAt.isAfter(remote.updatedAt)) return;
    await _local.upsertReminder(_reminderToCompanion(remote));
    if (remote.isDeleted) await _local.deleteReminderDeviceState(remote.noteId);
  }

  NoteRemindersTableCompanion _reminderToCompanion(NoteReminder r) =>
      NoteRemindersTableCompanion(
        noteId: Value(r.noteId),
        userId: Value(r.userId),
        remindAt: Value(r.remindAt),
        createdAt: Value(r.createdAt),
        updatedAt: Value(r.updatedAt),
        deletedAt: Value(r.deletedAt),
      );

  Map<String, dynamic> _payload(NoteReminder reminder) => {
        'note_id': reminder.noteId,
        'remind_at': reminder.remindAt.toUtc().toIso8601String(),
        'created_at': reminder.createdAt.toUtc().toIso8601String(),
        'updated_at': reminder.updatedAt.toUtc().toIso8601String(),
        'deleted_at': reminder.deletedAt?.toUtc().toIso8601String(),
      };

  String _pendingId(String noteId) => 'reminder_$noteId';
}
