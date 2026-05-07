import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/supabase_constants.dart';
import '../../models/note_model.dart';

class SupabaseNotesDatasource {
  final SupabaseClient _client;

  SupabaseNotesDatasource(this._client);

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw StateError('SupabaseNotesDatasource: no authenticated user');
    return id;
  }

  Future<List<NoteModel>> fetchAllNotes() async {
    final response = await _client
        .from(SupabaseConstants.notesTable)
        .select()
        .eq('user_id', _userId)
        .order('updated_at', ascending: false);
    return (response as List)
        .map((e) => NoteModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<NoteModel> insertNote(Map<String, dynamic> data) async {
    final response = await _client
        .from(SupabaseConstants.notesTable)
        .insert({...data, 'user_id': _userId})
        .select()
        .single();
    return NoteModel.fromJson(response);
  }

  Future<NoteModel> updateNote(String id, Map<String, dynamic> data) async {
    final response = await _client
        .from(SupabaseConstants.notesTable)
        .update({...data, 'updated_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id)
        .eq('user_id', _userId)
        .select()
        .single();
    return NoteModel.fromJson(response);
  }

  Future<void> deleteNote(String id) async {
    await _client
        .from(SupabaseConstants.notesTable)
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }

  Future<void> deleteNotesByCategoryId(String categoryId) async {
    await _client
        .from(SupabaseConstants.notesTable)
        .delete()
        .eq('category_id', categoryId)
        .eq('user_id', _userId);
  }

  RealtimeChannel? _notesChannel;

  Future<void> upsertNote(Map<String, dynamic> data) async {
    await _client
        .from(SupabaseConstants.notesTable)
        .upsert({...data, 'user_id': _userId});
  }

  void subscribeToNotes(
      void Function(bool isDelete, Map<String, dynamic> record) onEvent) {
    _notesChannel = _client
        .channel(SupabaseConstants.notesChannel)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: SupabaseConstants.notesTable,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: _userId,
          ),
          callback: (payload) {
            final isDelete = payload.eventType == PostgresChangeEvent.delete;
            onEvent(isDelete,
                isDelete ? payload.oldRecord : payload.newRecord);
          },
        )
        .subscribe();
  }

  void unsubscribeNotes() {
    _notesChannel?.unsubscribe();
    _notesChannel = null;
  }

  Future<NoteModel?> fetchNoteById(String id) async {
    final response = await _client
        .from(SupabaseConstants.notesTable)
        .select()
        .eq('id', id)
        .eq('user_id', _userId)
        .maybeSingle();
    if (response == null) return null;
    return NoteModel.fromJson(response as Map<String, dynamic>);
  }

  Future<void> updatePinOrders(List<Map<String, dynamic>> updates) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await Future.wait(updates.map((u) => _client
        .from(SupabaseConstants.notesTable)
        .update({'pin_order': u['pin_order'], 'updated_at': now})
        .eq('id', u['id'] as String)
        .eq('user_id', _userId)));
  }
}
