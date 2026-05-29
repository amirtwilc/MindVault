import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/supabase_constants.dart';
import '../../../core/utils/id_generator.dart';
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
    final now = DateTime.now().toUtc().toIso8601String();
    return upsertCategoryModel({
      'id': id ?? generateId(),
      'name': name,
      'sort_order': sortOrder,
      'color': color,
      'last_used_at': now,
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<void> upsertCategory(Map<String, dynamic> data) async {
    await upsertCategoryModel(data);
  }

  Future<CategoryModel> upsertCategoryModel(Map<String, dynamic> data) async {
    await ensureSupabaseProfile(_client);
    final response = await _client.rpc('upsert_cluster_lww', params: {
      'p_id': data['id'],
      'p_name': data['name'],
      'p_sort_order': data['sort_order'] ?? 0,
      'p_color': data['color'],
      'p_last_used_at': data['last_used_at'],
      'p_created_at': data['created_at'],
      'p_updated_at': data['updated_at'],
    });
    final rows = (response as List).cast<Map<String, dynamic>>();
    if (rows.isNotEmpty) return CategoryModel.fromJson(rows.first);
    final current = await fetchCategoryById(data['id'] as String);
    if (current == null) {
      throw StateError('Cluster LWW upsert returned no row for ${data['id']}');
    }
    return current;
  }

  Future<CategoryModel?> fetchCategoryById(String id) async {
    final response = await _client
        .from(SupabaseConstants.categoriesTable)
        .select()
        .eq('id', id)
        .eq('user_id', _userId)
        .maybeSingle();
    if (response == null) return null;
    return CategoryModel.fromJson(response);
  }

  Future<void> updateSortOrders(List<Map<String, dynamic>> updates) async {
    for (final update in updates) {
      final current = await fetchCategoryById(update['id'] as String);
      if (current == null) continue;
      await upsertCategory({
        'id': current.id,
        'name': current.name,
        'sort_order': update['sort_order'],
        'color': current.color,
        'last_used_at': current.lastUsedAt,
        'created_at': current.createdAt,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    }
  }

  Future<void> updateCategoryName(String id, String name) async {
    final current = await fetchCategoryById(id);
    if (current == null) return;
    await upsertCategory({
      'id': current.id,
      'name': name,
      'sort_order': current.sortOrder,
      'color': current.color,
      'last_used_at': current.lastUsedAt,
      'created_at': current.createdAt,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> updateCategoryColor(String id, String color) async {
    final current = await fetchCategoryById(id);
    if (current == null) return;
    await upsertCategory({
      'id': current.id,
      'name': current.name,
      'sort_order': current.sortOrder,
      'color': color,
      'last_used_at': current.lastUsedAt,
      'created_at': current.createdAt,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
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
            final record = isDelete ? payload.oldRecord : payload.newRecord;
            onEvent(isDelete, record);
          },
        )
        .subscribe();
  }
}
