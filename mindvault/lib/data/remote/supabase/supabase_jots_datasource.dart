import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../models/jot_model.dart';

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
    final response = await _client
        .from(SupabaseConstants.jotsTable)
        .insert({...data, 'user_id': _userId})
        .select()
        .single();
    return JotModel.fromJson(response);
  }

  Future<JotModel> upsertJot(Map<String, dynamic> data) async {
    final response = await _client
        .from(SupabaseConstants.jotsTable)
        .upsert({...data, 'user_id': _userId})
        .select()
        .single();
    return JotModel.fromJson(response);
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
