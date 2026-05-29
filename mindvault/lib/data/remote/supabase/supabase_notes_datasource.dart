import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/supabase_constants.dart';
import '../../models/checklist_item_model.dart';
import '../../models/note_reminder_model.dart';
import '../../models/note_model.dart';
import 'supabase_profile_bootstrap.dart';

class SupabaseNotesDatasource {
  final SupabaseClient _client;

  SupabaseNotesDatasource(this._client);

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw StateError('SupabaseNotesDatasource: no authenticated user');
    }
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
    return upsertNoteLww(data);
  }

  Future<NoteModel> updateNote(String id, Map<String, dynamic> data) async {
    return upsertNoteLww({'id': id, ...data});
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
  RealtimeChannel? _checklistItemsChannel;
  RealtimeChannel? _remindersChannel;

  Future<void> upsertNote(Map<String, dynamic> data) async {
    await upsertNoteLww(data);
  }

  Future<NoteModel> upsertNoteLww(Map<String, dynamic> data) async {
    await ensureSupabaseProfile(_client);
    final response = await _client.rpc('upsert_memory_lww', params: {
      'p_id': data['id'],
      'p_category_id': data['category_id'],
      'p_title': data['title'],
      'p_body': data['body'] ?? '',
      'p_is_private': data['is_private'] ?? false,
      'p_last_used_at': data['last_used_at'],
      'p_created_at': data['created_at'],
      'p_updated_at': data['updated_at'],
      'p_note_type': data['note_type'] ?? 'text',
      'p_is_pinned': data['is_pinned'] ?? false,
      'p_pinned_at': data['pinned_at'],
      'p_pin_order': data['pin_order'],
    });
    final rows = (response as List).cast<Map<String, dynamic>>();
    if (rows.isNotEmpty) return NoteModel.fromJson(rows.first);
    final current = await fetchNoteById(data['id'] as String);
    if (current == null) {
      throw StateError('Memory LWW upsert returned no row for ${data['id']}');
    }
    return current;
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
            onEvent(isDelete, isDelete ? payload.oldRecord : payload.newRecord);
          },
        )
        .subscribe();
  }

  void unsubscribeNotes() {
    _notesChannel?.unsubscribe();
    _notesChannel = null;
    _checklistItemsChannel?.unsubscribe();
    _checklistItemsChannel = null;
  }

  void unsubscribeReminders() {
    _remindersChannel?.unsubscribe();
    _remindersChannel = null;
  }

  Future<List<NoteReminderModel>> fetchAllReminders() async {
    final response = await _client
        .from(SupabaseConstants.noteRemindersTable)
        .select()
        .eq('user_id', _userId)
        .order('updated_at', ascending: false);
    return (response as List)
        .map((e) => NoteReminderModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<NoteReminderModel?> fetchReminderByNoteId(String noteId) async {
    final response = await _client
        .from(SupabaseConstants.noteRemindersTable)
        .select()
        .eq('note_id', noteId)
        .eq('user_id', _userId)
        .maybeSingle();
    if (response == null) return null;
    return NoteReminderModel.fromJson(response);
  }

  Future<NoteReminderModel> upsertReminder(Map<String, dynamic> data) async {
    await ensureSupabaseProfile(_client);
    final response = await _client.rpc('upsert_memory_reminder_lww', params: {
      'p_note_id': data['note_id'],
      'p_remind_at': data['remind_at'],
      'p_created_at': data['created_at'],
      'p_updated_at': data['updated_at'],
      'p_deleted_at': data['deleted_at'],
    });
    final rows = (response as List).cast<Map<String, dynamic>>();
    if (rows.isNotEmpty) return NoteReminderModel.fromJson(rows.first);
    final current = await fetchReminderByNoteId(data['note_id'] as String);
    if (current == null) {
      throw StateError(
          'Reminder LWW upsert returned no row for ${data['note_id']}');
    }
    return current;
  }

  void subscribeToReminders(
      void Function(bool isDelete, Map<String, dynamic> record) onEvent) {
    _remindersChannel = _client
        .channel(SupabaseConstants.noteRemindersChannel)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: SupabaseConstants.noteRemindersTable,
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

  Future<NoteModel?> fetchNoteById(String id) async {
    final response = await _client
        .from(SupabaseConstants.notesTable)
        .select()
        .eq('id', id)
        .eq('user_id', _userId)
        .maybeSingle();
    if (response == null) return null;
    return NoteModel.fromJson(response);
  }

  Future<void> updatePinOrders(List<Map<String, dynamic>> updates) async {
    final now = DateTime.now().toUtc().toIso8601String();
    for (final update in updates) {
      final current = await fetchNoteById(update['id'] as String);
      if (current == null) continue;
      await upsertNote({
        ...current.toJson(),
        'pin_order': update['pin_order'],
        'updated_at': now,
      });
    }
  }

  Future<List<ChecklistItemModel>> fetchChecklistItems(String noteId) async {
    final response = await _client
        .from(SupabaseConstants.checklistItemsTable)
        .select()
        .eq('note_id', noteId)
        .eq('user_id', _userId)
        .order('sort_order', ascending: true);
    return (response as List)
        .map((e) => ChecklistItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ChecklistItemModel>> fetchAllChecklistItems() async {
    final response = await _client
        .from(SupabaseConstants.checklistItemsTable)
        .select()
        .eq('user_id', _userId)
        .order('updated_at', ascending: false);
    return (response as List)
        .map((e) => ChecklistItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ChecklistItemModel?> fetchChecklistItemById(String id) async {
    final response = await _client
        .from(SupabaseConstants.checklistItemsTable)
        .select()
        .eq('id', id)
        .eq('user_id', _userId)
        .maybeSingle();
    if (response == null) return null;
    return ChecklistItemModel.fromJson(response);
  }

  Future<ChecklistItemModel> upsertChecklistItem(
      Map<String, dynamic> data) async {
    await ensureSupabaseProfile(_client);
    final response = await _client.rpc('upsert_plan_item_lww', params: {
      'p_id': data['id'],
      'p_note_id': data['note_id'],
      'p_text': data['text'],
      'p_is_completed': data['is_completed'] ?? false,
      'p_sort_order': data['sort_order'] ?? 0,
      'p_completed_at': data['completed_at'],
      'p_created_at': data['created_at'],
      'p_updated_at': data['updated_at'],
    });
    final rows = (response as List).cast<Map<String, dynamic>>();
    if (rows.isNotEmpty) return ChecklistItemModel.fromJson(rows.first);
    final current = await fetchChecklistItemById(data['id'] as String);
    if (current == null) {
      throw StateError(
          'Plan item LWW upsert returned no row for ${data['id']}');
    }
    return current;
  }

  Future<void> upsertChecklistItems(List<Map<String, dynamic>> items) async {
    if (items.isEmpty) return;
    for (final item in items) {
      await upsertChecklistItem(item);
    }
  }

  Future<void> deleteChecklistItem(String id) async {
    await _client
        .from(SupabaseConstants.checklistItemsTable)
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }

  Future<void> deleteChecklistItemsByNoteId(String noteId) async {
    await _client
        .from(SupabaseConstants.checklistItemsTable)
        .delete()
        .eq('note_id', noteId)
        .eq('user_id', _userId);
  }

  void subscribeToChecklistItems(
      void Function(bool isDelete, Map<String, dynamic> record) onEvent) {
    _checklistItemsChannel = _client
        .channel(SupabaseConstants.checklistItemsChannel)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: SupabaseConstants.checklistItemsTable,
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
}
