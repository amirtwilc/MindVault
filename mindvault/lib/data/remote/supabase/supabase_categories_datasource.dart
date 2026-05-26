import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/supabase_constants.dart';
import '../../models/category_model.dart';
import 'supabase_profile_bootstrap.dart';

class SupabaseCategoriesDatasource {
  final SupabaseClient _client;

  SupabaseCategoriesDatasource(this._client);

  String get _userId => _client.auth.currentUser!.id;

  Future<List<CategoryModel>> fetchCategories() async {
    final response = await _client
        .from(SupabaseConstants.categoriesTable)
        .select()
        .eq('user_id', _userId)
        .order('sort_order', ascending: true);
    return (response as List)
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CategoryModel> insertCategory(String name, int sortOrder,
      {String? color, String? id}) async {
    await ensureSupabaseProfile(_client);
    final payload = <String, dynamic>{
      'user_id': _userId,
      'name': name,
      'sort_order': sortOrder,
    };
    if (id != null) payload['id'] = id;
    if (color != null) payload['color'] = color;
    final response = await _client
        .from(SupabaseConstants.categoriesTable)
        .insert(payload)
        .select()
        .single();
    return CategoryModel.fromJson(response);
  }

  Future<void> upsertCategory(Map<String, dynamic> data) async {
    await ensureSupabaseProfile(_client);
    await _client
        .from(SupabaseConstants.categoriesTable)
        .upsert({...data, 'user_id': _userId});
  }

  Future<void> updateSortOrders(List<Map<String, dynamic>> updates) async {
    for (final update in updates) {
      await _client
          .from(SupabaseConstants.categoriesTable)
          .update({'sort_order': update['sort_order']})
          .eq('id', update['id'])
          .eq('user_id', _userId);
    }
  }

  Future<void> updateCategoryName(String id, String name) async {
    await _client
        .from(SupabaseConstants.categoriesTable)
        .update({'name': name})
        .eq('id', id)
        .eq('user_id', _userId);
  }

  Future<void> updateCategoryColor(String id, String color) async {
    await _client
        .from(SupabaseConstants.categoriesTable)
        .update({'color': color})
        .eq('id', id)
        .eq('user_id', _userId);
  }

  Future<void> deleteCategory(String id) async {
    await _client
        .from(SupabaseConstants.categoriesTable)
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }

  RealtimeChannel subscribeToCategories(
      void Function(bool isDelete, Map<String, dynamic> record) onEvent) {
    return _client
        .channel(SupabaseConstants.categoriesChannel)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: SupabaseConstants.categoriesTable,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: _userId,
          ),
          callback: (payload) {
            final isDelete = payload.eventType == PostgresChangeEvent.delete;
            final record = isDelete
                ? (payload.oldRecord ?? {})
                : (payload.newRecord ?? {});
            onEvent(isDelete, record);
          },
        )
        .subscribe();
  }
}
