import 'package:drift/drift.dart';
import 'package:encrypt/encrypt.dart';

import '../../core/utils/id_generator.dart';
import '../../domain/entities/jot.dart';
import '../../domain/repositories/jot_repository.dart';
import '../../services/encryption_service.dart';
import '../../services/error_log_service.dart';
import '../local/database/app_database.dart';
import '../local/database/note_mappers.dart';
import '../models/jot_model.dart';
import '../remote/supabase/supabase_jots_datasource.dart';

class JotRepositoryImpl implements JotRepository {
  final SupabaseJotsDatasource _remote;
  final AppDatabase _local;
  final EncryptionService _encryption;
  final Key _aesKey;
  final String _userId;
  final ErrorLogger _errorLogger;

  JotRepositoryImpl({
    required SupabaseJotsDatasource remote,
    required AppDatabase local,
    required EncryptionService encryption,
    required Key aesKey,
    required String userId,
    ErrorLogger errorLogger = const NoopErrorLogger(),
  })  : _remote = remote,
        _local = local,
        _encryption = encryption,
        _aesKey = aesKey,
        _userId = userId,
        _errorLogger = errorLogger;

  String _enc(String text) => _encryption.encrypt(text, _aesKey);
  String _dec(String cipher) => _encryption.decrypt(cipher, _aesKey);
  String? _encNullable(String? text) => text == null ? null : _enc(text);
  String? _decNullable(String? cipher) => cipher == null ? null : _dec(cipher);

  @override
  void startSync() {
    _syncAllJots();
    _remote.subscribeToJots((isDelete, record) async {
      try {
        final id = record['id'] as String?;
        if (id == null) return;
        if (await _hasPendingJotMutation(id)) return;
        if (isDelete) {
          await _local.deleteJot(id);
        } else {
          final jot = _decryptModel(JotModel.fromJson(record));
          await _mergeRemoteJot(jot);
        }
      } catch (e) {
        _errorLogger.report(source: 'realtime_jots', message: e.toString());
      }
    });
  }

  @override
  void stopSync() => _remote.unsubscribeJots();

  @override
  Stream<List<Jot>> watchUnhandledJots({
    JotSortOrder sortOrder = JotSortOrder.oldestFirst,
  }) {
    return _local
        .watchUnhandledJots(
          _userId,
          newestFirst: sortOrder.newestFirstSelected,
        )
        .map((rows) => rows.map(rowToJot).toList());
  }

  @override
  Future<List<Jot>> getUnhandledJots({
    JotSortOrder sortOrder = JotSortOrder.oldestFirst,
  }) async {
    final rows = await _local.getUnhandledJots(
      _userId,
      newestFirst: sortOrder.newestFirstSelected,
    );
    return rows.map(rowToJot).toList();
  }

  @override
  Future<Jot?> getJotById(String id) async {
    final row = await _local.getJot(id);
    return row == null ? null : rowToJot(row);
  }

  @override
  Future<Jot> createJot({required String text}) async {
    final now = DateTime.now().toUtc();
    final jot = Jot(
      id: generateId(),
      userId: _userId,
      text: text,
      createdAt: now,
      updatedAt: now,
    );
    await _local.upsertJot(_jotToCompanion(jot));
    try {
      final synced = _decryptModel(await _remote.insertJot(_payload(jot)));
      await _local.upsertJot(_jotToCompanion(synced));
      return synced;
    } catch (_) {
      await _local.upsertPendingOp(jot.id, 'create_jot', jot.id);
      return jot;
    }
  }

  @override
  Future<Jot?> updateJot({
    required String id,
    String? text,
    DateTime? handledAt,
    DateTime? aiProcessedAt,
    String? aiSuggestionJson,
    String? aiSuggestionRunId,
    DateTime? reminderAt,
  }) async {
    final row = await _local.getJot(id);
    if (row == null) return null;
    final now = DateTime.now().toUtc();
    final updated = rowToJot(row).copyWith(
      text: text,
      handledAt: handledAt ?? row.handledAt,
      aiProcessedAt: aiProcessedAt ?? row.aiProcessedAt,
      aiSuggestionJson: aiSuggestionJson ?? row.aiSuggestionJson,
      aiSuggestionRunId: aiSuggestionRunId ?? row.aiSuggestionRunId,
      reminderAt: reminderAt ?? row.reminderAt,
      updatedAt: now,
    );
    await _local.upsertJot(_jotToCompanion(updated));
    try {
      final data = _payload(updated);
      final synced = _decryptModel(await _remote.upsertJot(data));
      await _local.upsertJot(_jotToCompanion(synced));
      await _local.deletePendingOp(id);
      return synced;
    } catch (_) {
      await _local.upsertPendingOp(id, 'update_jot', id);
      return updated;
    }
  }

  @override
  Future<Jot?> clearReminder(String id) async {
    final row = await _local.getJot(id);
    if (row == null) return null;
    final now = DateTime.now().toUtc();
    final updated = rowToJot(row).copyWith(
      reminderAt: null,
      updatedAt: now,
    );
    await _local.upsertJot(_jotToCompanion(updated));
    try {
      final data = _payload(updated);
      final synced = _decryptModel(await _remote.upsertJot(data));
      await _local.upsertJot(_jotToCompanion(synced));
      await _local.deletePendingOp(id);
      return synced;
    } catch (_) {
      await _local.upsertPendingOp(id, 'update_jot', id);
      return updated;
    }
  }

  @override
  Future<void> markHandled(String id) async {
    await updateJot(id: id, handledAt: DateTime.now().toUtc());
  }

  @override
  Future<void> deleteJot(String id) async {
    await _local.deleteJot(id);
    await _local.removePendingOpsForRecord(id);
    try {
      await _remote.deleteJot(id);
    } catch (_) {
      await _local.upsertPendingOp('del_jot_$id', 'delete_jot', id);
    }
  }

  @override
  Future<void> deleteJots(List<String> ids) async {
    for (final id in ids) {
      await deleteJot(id);
    }
  }

  @override
  Future<void> syncPendingOps() async {
    final ops = await _local.getPendingOps();
    for (final op in ops.where((o) =>
        o.opType == 'create_jot' ||
        o.opType == 'update_jot' ||
        o.opType == 'delete_jot')) {
      try {
        if (op.opType == 'delete_jot') {
          await _remote.deleteJot(op.recordId);
          await _local.deleteJot(op.recordId);
        } else {
          final row = await _local.getJot(op.recordId);
          if (row == null) {
            await _local.deletePendingOp(op.id);
            continue;
          }
          final jot = rowToJot(row);
          if (op.opType == 'update_jot') {
            try {
              final remote = await _remote.fetchJotById(jot.id);
              if (remote != null &&
                  DateTime.parse(remote.updatedAt).isAfter(jot.updatedAt)) {
                await _local.deletePendingOp(op.id);
                continue;
              }
            } catch (_) {}
          }
          await _remote.upsertJot(_payload(jot));
        }
        await _local.deletePendingOp(op.id);
      } catch (_) {}
    }
    await _syncAllJots();
  }

  Future<void> _syncAllJots() async {
    try {
      final models = await _remote.fetchAllJots();
      final remoteIds = <String>{};
      for (final model in models) {
        remoteIds.add(model.id);
        if (await _hasPendingJotMutation(model.id)) continue;
        try {
          await _mergeRemoteJot(_decryptModel(model));
        } catch (e) {
          _errorLogger.report(
            source: 'sync_all_jots_row',
            message: e.toString(),
          );
        }
      }

      final pendingUpsertIds = (await _local.getPendingOps())
          .where((o) => o.opType == 'create_jot' || o.opType == 'update_jot')
          .map((o) => o.recordId)
          .toSet();
      final localJots = await _local.getAllJots(_userId);
      for (final row in localJots) {
        if (!remoteIds.contains(row.id) && !pendingUpsertIds.contains(row.id)) {
          await _local.deleteJot(row.id);
        }
      }
    } catch (e) {
      _errorLogger.report(source: 'sync_all_jots', message: e.toString());
    }
  }

  Future<bool> _hasPendingJotMutation(String jotId) async {
    final ops = await _local.getPendingOps();
    return ops.any((op) =>
        op.recordId == jotId &&
        (op.opType == 'create_jot' ||
            op.opType == 'update_jot' ||
            op.opType == 'delete_jot'));
  }

  Future<void> _mergeRemoteJot(Jot remote) async {
    final local = await _local.getJot(remote.id);
    if (local != null && local.updatedAt.isAfter(remote.updatedAt)) return;
    await _local.upsertJot(_jotToCompanion(remote));
  }

  Jot _decryptModel(JotModel model) => Jot(
        id: model.id,
        userId: model.userId,
        text: _dec(model.text),
        createdAt: DateTime.parse(model.createdAt).toUtc(),
        updatedAt: DateTime.parse(model.updatedAt).toUtc(),
        handledAt: model.handledAt == null
            ? null
            : DateTime.parse(model.handledAt!).toUtc(),
        aiProcessedAt: model.aiProcessedAt == null
            ? null
            : DateTime.parse(model.aiProcessedAt!).toUtc(),
        aiSuggestionJson: _decNullable(model.aiSuggestionJson),
        aiSuggestionRunId: model.aiSuggestionRunId,
        reminderAt: model.reminderAt == null
            ? null
            : DateTime.parse(model.reminderAt!).toUtc(),
      );

  JotsTableCompanion _jotToCompanion(Jot jot) => JotsTableCompanion(
        id: Value(jot.id),
        userId: Value(jot.userId),
        jotText: Value(jot.text),
        createdAt: Value(jot.createdAt),
        updatedAt: Value(jot.updatedAt),
        handledAt: Value(jot.handledAt),
        aiProcessedAt: Value(jot.aiProcessedAt),
        aiSuggestionJson: Value(jot.aiSuggestionJson),
        aiSuggestionRunId: Value(jot.aiSuggestionRunId),
        reminderAt: Value(jot.reminderAt),
      );

  Map<String, dynamic> _payload(Jot jot) => {
        'id': jot.id,
        'text': _enc(jot.text),
        'created_at': jot.createdAt.toUtc().toIso8601String(),
        'updated_at': jot.updatedAt.toUtc().toIso8601String(),
        'handled_at': jot.handledAt?.toUtc().toIso8601String(),
        'ai_processed_at': jot.aiProcessedAt?.toUtc().toIso8601String(),
        'ai_suggestion_json': _encNullable(jot.aiSuggestionJson),
        'ai_suggestion_run_id': jot.aiSuggestionRunId,
        'reminder_at': jot.reminderAt?.toUtc().toIso8601String(),
      };
}
