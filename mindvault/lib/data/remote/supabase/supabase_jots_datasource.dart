import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../models/jot_model.dart';
import 'supabase_profile_bootstrap.dart';

class SupabaseJotsDatasource {
  final SupabaseClient _client;

  SupabaseJotsDatasource(this._client);

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw StateError('SupabaseJotsDatasource: no authenticated user');
    }
    return id;
  }

  Future<List<JotModel>> fetchAllJots() async {
    final response = await _client
        .from(SupabaseConstants.jotsTable)
        .select()
        .eq('user_id', _userId)
        .order('updated_at', ascending: false);
    return (response as List)
        .map((e) => JotModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<JotModel?> fetchJotById(String id) async {
    final response = await _client
        .from(SupabaseConstants.jotsTable)
        .select()
        .eq('id', id)
        .eq('user_id', _userId)
        .maybeSingle();
    if (response == null) return null;
    return JotModel.fromJson(response);
  }

  Future<JotModel> insertJot(Map<String, dynamic> data) async {
    return upsertJot(data);
  }

  Future<JotModel> upsertJot(Map<String, dynamic> data) async {
    await ensureSupabaseProfile(_client);
    final response = await _client.rpc('upsert_spark_lww', params: {
      'p_id': data['id'],
      'p_text': data['text'],
      'p_created_at': data['created_at'],
      'p_updated_at': data['updated_at'],
      'p_handled_at': data['handled_at'],
      'p_ai_processed_at': data['ai_processed_at'],
      'p_ai_suggestion_json': data['ai_suggestion_json'],
      'p_ai_suggestion_run_id': data['ai_suggestion_run_id'],
      'p_reminder_at': data['reminder_at'],
    });
    final rows = (response as List).cast<Map<String, dynamic>>();
    if (rows.isNotEmpty) return JotModel.fromJson(rows.first);
    final current = await fetchJotById(data['id'] as String);
    if (current == null) {
      throw StateError('Spark LWW upsert returned no row for ${data['id']}');
    }
    return current;
  }

  Future<void> deleteJot(String id) async {
    await _client
        .from(SupabaseConstants.jotsTable)
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }

  RealtimeChannel? _jotsChannel;

  void subscribeToJots(
      void Function(bool isDelete, Map<String, dynamic> record) onEvent) {
    _jotsChannel = _client
        .channel(SupabaseConstants.jotsChannel)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: SupabaseConstants.jotsTable,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: _userId,
          ),
          callback: (payload) {
            final isDelete = payload.eventType == PostgresChangeEvent.delete;
            onEvent(isDelete, isDelete ? payload.oldRecord : payload.newRecord);
          },
        )
        .subscribe();
  }

  void unsubscribeJots() {
    _jotsChannel?.unsubscribe();
    _jotsChannel = null;
  }
}
