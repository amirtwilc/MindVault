import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/category_defaults.dart';
import '../../core/utils/id_generator.dart';
import '../../data/local/database/app_database.dart';
import '../../data/models/category_model.dart';
import '../../data/remote/supabase/supabase_categories_datasource.dart';
import '../../domain/entities/category.dart';
import 'analytics_provider.dart';
import 'auth_provider.dart';
import 'database_provider.dart';
import 'error_log_provider.dart';
import 'notes_provider.dart';

final categoriesDatasourceProvider =
    Provider<SupabaseCategoriesDatasource>((ref) {
  return SupabaseCategoriesDatasource(ref.watch(supabaseClientProvider));
});

final categoriesProvider =
    AsyncNotifierProvider<CategoriesNotifier, List<Category>>(
  CategoriesNotifier.new,
);

class CategoriesNotifier extends AsyncNotifier<List<Category>> {
  @override
  Future<List<Category>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];

    final datasource = ref.read(categoriesDatasourceProvider);
    final channel = datasource.subscribeToCategories(_handleRealtimeEvent);
    ref.onDispose(channel.unsubscribe);

    var local = await _loadFromDrift();

    // Failsafe: ensure the General category always exists.
    if (!local.any((c) => isGeneralCategoryName(c.name))) {
      await _createGeneralCategory(sortOrder: local.length);
      local = await _loadFromDrift();
    }

    _catchUpSync({});
    return local;
  }

  // ── Drift read path ───────────────────────────────────────────

  Future<List<Category>> _loadFromDrift() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return [];
    final db = ref.read(appDatabaseProvider);
    final rows = await (db.select(db.categoriesTable)
          ..where((t) => t.userId.equals(user.id))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
    return rows
        .map((r) => Category(
              id: r.id,
              userId: r.userId,
              name: r.name,
              sortOrder: r.sortOrder,
              color: r.color,
              lastUsedAt: r.lastUsedAt,
              createdAt: r.createdAt,
            ))
        .toList();
  }

  Future<void> _reloadFromDrift() async {
    final cats = await _loadFromDrift();
    state = AsyncData(cats);
  }

  Future<bool> _hasPendingCategoryMutation(String id) async {
    final ops = await ref.read(appDatabaseProvider).getPendingOps();
    return ops.any((op) =>
        op.recordId == id &&
        (op.opType == 'upsert_cluster' ||
            op.opType == 'create_cluster' ||
            op.opType == 'update_cluster' ||
            op.opType == 'upsert_category' ||
            op.opType == 'create_category' ||
            op.opType == 'update_category' ||
            op.opType == 'delete_cluster' ||
            op.opType == 'delete_category'));
  }

  Future<void> _reportError(
    String source,
    Object error, {
    Map<String, dynamic>? context,
  }) async {
    try {
      await ref.read(errorLoggerProvider).report(
            source: source,
            message: error.toString(),
            context: context,
          );
    } catch (_) {
      // Logging must never keep background sync work alive or fail tests when
      // the provider has already been disposed.
    }
  }

  // ── Supabase catch-up sync ─────────────────────────────────────

  Future<void> _catchUpSync(Set<String> justSyncedIds) async {
    try {
      final datasource = ref.read(categoriesDatasourceProvider);
      final db = ref.read(appDatabaseProvider);
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      final models = await datasource.fetchCategories();
      final remoteIds = models.map((m) => m.id).toSet();
      final pendingCatIds = (await db.getPendingOps())
          .where((op) =>
              op.opType == 'upsert_cluster' ||
              op.opType == 'create_cluster' ||
              op.opType == 'update_cluster' ||
              op.opType == 'upsert_category' ||
              op.opType == 'create_category' ||
              op.opType == 'update_category' ||
              op.opType == 'delete_cluster' ||
              op.opType == 'delete_category')
          .map((op) => op.recordId)
          .toSet();

      // Read existing rows before upserting — used for color preservation and deletion check.
      final existingRows = await (db.select(db.categoriesTable)
            ..where((t) => t.userId.equals(user.id)))
          .get();
      final driftColorMap = {for (final r in existingRows) r.id: r.color};

      final companions = models
          .where((m) => !pendingCatIds.contains(m.id))
          .map((m) => CategoriesTableCompanion(
                id: Value(m.id),
                userId: Value(m.userId),
                name: Value(m.name),
                sortOrder: Value(m.sortOrder),
                color: Value(m.color ?? driftColorMap[m.id]),
                lastUsedAt: Value(DateTime.parse(m.lastUsedAt).toUtc()),
                createdAt: Value(DateTime.parse(m.createdAt).toUtc()),
                updatedAt: Value(
                    DateTime.parse(m.updatedAt ?? m.createdAt).toUtc()),
              ))
          .toList();
      await db.upsertCategories(companions);

      for (final row in existingRows) {
        if (!remoteIds.contains(row.id) &&
            !justSyncedIds.contains(row.id) &&
            !pendingCatIds.contains(row.id)) {
          await db.deleteCategory(row.id);
        }
      }

      await _reloadFromDrift();

      // Failsafe: re-ensure General exists after a remote sync that might
      // have removed it (e.g. synced from a device that deleted it).
      final current = state.valueOrNull ?? [];
      if (!current.any((c) => isGeneralCategoryName(c.name))) {
        await _createGeneralCategory(sortOrder: current.length);
        await _reloadFromDrift();
      }
    } catch (e) {
      await _reportError('categories_catch_up', e);
    }
  }

  // ── Realtime handler ──────────────────────────────────────────

  Future<void> _handleRealtimeEvent(
      bool isDelete, Map<String, dynamic> record) async {
    try {
      final db = ref.read(appDatabaseProvider);
      final id = record['id'] as String?;
      if (id == null) return;
      if (await _hasPendingCategoryMutation(id)) return;
      if (isDelete) {
        await db.deleteCategory(id);
      } else {
        String? color = record['color'] as String?;
        if (color == null) {
          final existing = await (db.select(db.categoriesTable)
                ..where((t) => t.id.equals(id)))
              .getSingleOrNull();
          color = existing?.color;
        }
        await db.upsertCategory(CategoriesTableCompanion(
          id: Value(id),
          userId: Value(record['user_id'] as String),
          name: Value(record['name'] as String),
          sortOrder: Value(record['sort_order'] as int? ?? 0),
          color: Value(color),
          lastUsedAt: Value(_parseDate(record['last_used_at'])),
          createdAt: Value(_parseDate(record['created_at'])),
          updatedAt: Value(_parseDate(record['updated_at'])),
        ));
      }
      await _reloadFromDrift();
    } catch (e) {
      await _reportError('realtime_categories', e);
    }
  }

  DateTime _parseDate(dynamic v) =>
      v != null ? DateTime.parse(v as String).toUtc() : DateTime.now().toUtc();

  // ── General category failsafe ─────────────────────────────────

  Future<void> _createGeneralCategory({int sortOrder = 0}) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final db = ref.read(appDatabaseProvider);

    // Guard against races: re-read Drift before inserting.
    final existing = await _loadFromDrift();
    if (existing.any((c) => isGeneralCategoryName(c.name))) return;

    // On reinstall, local DB is empty but Supabase already has a General
    // (created by the DB trigger on first sign-up, or from a previous session).
    // Sync it locally instead of generating a new UUID — which would conflict
    // with the UNIQUE(user_id, name) constraint and create a phantom local copy.
    try {
      final datasource = ref.read(categoriesDatasourceProvider);
      final remote = await datasource.fetchCategories();
      final CategoryModel? remoteGeneral =
          remote.where((m) => isGeneralCategoryName(m.name)).firstOrNull;
      if (remoteGeneral != null) {
        final check = await _loadFromDrift();
        if (check.any((c) => isGeneralCategoryName(c.name))) return;
        await db.upsertCategory(CategoriesTableCompanion(
          id: Value(remoteGeneral.id),
          userId: Value(remoteGeneral.userId),
          name: Value(remoteGeneral.name),
          sortOrder: Value(remoteGeneral.sortOrder),
          color: Value(remoteGeneral.color),
          lastUsedAt: Value(DateTime.parse(remoteGeneral.lastUsedAt).toUtc()),
          createdAt: Value(DateTime.parse(remoteGeneral.createdAt).toUtc()),
          updatedAt: Value(DateTime.parse(
                  remoteGeneral.updatedAt ?? remoteGeneral.createdAt)
              .toUtc()),
        ));
        return;
      }
    } catch (_) {
      // Network unavailable — fall through to create locally with a pending op.
    }

    // No General in Supabase — create a fresh one.
    final id = generateId();
    final now = DateTime.now().toUtc();

    await db.upsertCategory(CategoriesTableCompanion(
      id: Value(id),
      userId: Value(user.id),
      name: const Value(kGeneralCategoryName),
      sortOrder: Value(sortOrder),
      color: const Value(null),
      lastUsedAt: Value(now),
      createdAt: Value(now),
      updatedAt: Value(now),
    ));

    try {
      await ref
          .read(categoriesDatasourceProvider)
          .insertCategory(kGeneralCategoryName, sortOrder, id: id);
    } catch (_) {
      await db.upsertPendingOp('cat_$id', 'upsert_cluster', id);
    }
  }

  // ── CRUD ──────────────────────────────────────────────────────

  Future<String?> createCategory(String name, {String? color}) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return null;
    final db = ref.read(appDatabaseProvider);
    final current = state.valueOrNull ?? [];
    final sortOrder = current.length;
    final id = generateId();
    final now = DateTime.now().toUtc();

    await db.upsertPendingOp('cat_$id', 'upsert_cluster', id);
    await db.upsertCategory(CategoriesTableCompanion(
      id: Value(id),
      userId: Value(user.id),
      name: Value(name),
      sortOrder: Value(sortOrder),
      color: Value(color),
      lastUsedAt: Value(now),
      createdAt: Value(now),
      updatedAt: Value(now),
    ));
    await _reloadFromDrift();
    ref.read(analyticsServiceProvider).track('category_created');

    final datasource = ref.read(categoriesDatasourceProvider);
    try {
      await datasource.insertCategory(name, sortOrder, color: color, id: id);
      await db.deletePendingOp('cat_$id');
    } catch (e) {
      await _reportError(
        'create_cluster_remote',
        e,
        context: {'cluster_id': id},
      );
    }
    return id;
  }

  Future<void> reorder(List<String> orderedIds) async {
    final db = ref.read(appDatabaseProvider);
    final current = state.valueOrNull ?? [];
    final lookup = {for (final c in current) c.id: c};

    final withOrder = orderedIds
        .where(lookup.containsKey)
        .toList()
        .asMap()
        .entries
        .map((e) => lookup[e.value]!.copyWith(sortOrder: e.key))
        .toList();

    // Optimistic update — show new order immediately so the list never flickers back.
    state = AsyncData(withOrder);

    final now = DateTime.now().toUtc();
    for (final c in withOrder) {
      await db.upsertPendingOp('cat_${c.id}', 'upsert_cluster', c.id);
    }
    for (final c in withOrder) {
      await db.upsertCategory(CategoriesTableCompanion(
        id: Value(c.id),
        userId: Value(c.userId),
        name: Value(c.name),
        sortOrder: Value(c.sortOrder),
        color: Value(c.color),
        lastUsedAt: Value(c.lastUsedAt),
        createdAt: Value(c.createdAt),
        updatedAt: Value(now),
      ));
    }

    final datasource = ref.read(categoriesDatasourceProvider);
    try {
      for (final c in withOrder) {
        await datasource.upsertCategory({
          'id': c.id,
          'name': c.name,
          'sort_order': c.sortOrder,
          'color': c.color,
          'last_used_at': c.lastUsedAt.toUtc().toIso8601String(),
          'created_at': c.createdAt.toUtc().toIso8601String(),
          'updated_at': now.toIso8601String(),
        });
      }
      for (final c in withOrder) {
        await db.deletePendingOp('cat_${c.id}');
      }
    } catch (e) {
      await _reportError('reorder_clusters_remote', e);
    }
  }

  Future<void> renameCategory(String id, String newName) async {
    final db = ref.read(appDatabaseProvider);
    final current = state.valueOrNull ?? [];
    final cat = current.where((c) => c.id == id).firstOrNull;
    if (cat == null) return;
    if (isGeneralCategoryName(cat.name)) return;
    final now = DateTime.now().toUtc();

    await db.upsertPendingOp('cat_$id', 'upsert_cluster', id);
    await db.upsertCategory(CategoriesTableCompanion(
      id: Value(id),
      userId: Value(cat.userId),
      name: Value(newName),
      sortOrder: Value(cat.sortOrder),
      color: Value(cat.color),
      lastUsedAt: Value(cat.lastUsedAt),
      createdAt: Value(cat.createdAt),
      updatedAt: Value(now),
    ));
    await _reloadFromDrift();

    try {
      await ref.read(categoriesDatasourceProvider).upsertCategory({
        'id': id,
        'name': newName,
        'sort_order': cat.sortOrder,
        'color': cat.color,
        'last_used_at': cat.lastUsedAt.toUtc().toIso8601String(),
        'created_at': cat.createdAt.toUtc().toIso8601String(),
        'updated_at': now.toIso8601String(),
      });
      await db.deletePendingOp('cat_$id');
    } catch (e) {
      await _reportError(
        'rename_cluster_remote',
        e,
        context: {'cluster_id': id},
      );
    }
  }

  Future<void> updateCategoryColor(String id, String color) async {
    final db = ref.read(appDatabaseProvider);
    final current = state.valueOrNull ?? [];
    final cat = current.where((c) => c.id == id).firstOrNull;
    if (cat == null) return;
    if (isGeneralCategoryName(cat.name)) return;
    final now = DateTime.now().toUtc();

    await db.upsertPendingOp('cat_$id', 'upsert_cluster', id);
    await db.upsertCategory(CategoriesTableCompanion(
      id: Value(id),
      userId: Value(cat.userId),
      name: Value(cat.name),
      sortOrder: Value(cat.sortOrder),
      color: Value(color),
      lastUsedAt: Value(cat.lastUsedAt),
      createdAt: Value(cat.createdAt),
      updatedAt: Value(now),
    ));
    await _reloadFromDrift();

    try {
      await ref.read(categoriesDatasourceProvider).upsertCategory({
        'id': id,
        'name': cat.name,
        'sort_order': cat.sortOrder,
        'color': color,
        'last_used_at': cat.lastUsedAt.toUtc().toIso8601String(),
        'created_at': cat.createdAt.toUtc().toIso8601String(),
        'updated_at': now.toIso8601String(),
      });
      await db.deletePendingOp('cat_$id');
    } catch (e) {
      await _reportError(
        'update_cluster_color_remote',
        e,
        context: {'cluster_id': id},
      );
    }
  }

  Future<void> deleteCategory(String id) async {
    final current = state.valueOrNull ?? [];
    final cat = current.where((c) => c.id == id).firstOrNull;
    if (cat != null && isGeneralCategoryName(cat.name)) return;

    final db = ref.read(appDatabaseProvider);

    await ref
        .read(notesDatasourceProvider)
        .deleteNotesByCategoryId(id)
        .catchError((_) {});
    await db.deleteNotesByCategoryId(id);
    await db.removePendingOpsForRecord(id);
    await db.deletePendingOp('cat_$id');
    await db.upsertPendingOp('catdel_$id', 'delete_cluster', id);
    await db.deleteCategory(id);
    await _reloadFromDrift();

    try {
      await ref.read(categoriesDatasourceProvider).deleteCategory(id);
      await db.deletePendingOp('catdel_$id');
    } catch (e) {
      await _reportError(
        'delete_cluster_remote',
        e,
        context: {'cluster_id': id},
      );
    }
  }

  // ── Offline sync ──────────────────────────────────────────────

  Future<void> syncPendingCategoryOps() async {
    final db = ref.read(appDatabaseProvider);
    final datasource = ref.read(categoriesDatasourceProvider);
    final ops = await db.getPendingOps();
    final catOps = ops.where((o) =>
        o.opType == 'upsert_cluster' ||
        o.opType == 'create_cluster' ||
        o.opType == 'update_cluster' ||
        o.opType == 'upsert_category' ||
        o.opType == 'create_category' ||
        o.opType == 'update_category' ||
        o.opType == 'delete_cluster' ||
        o.opType == 'delete_category');

    final justSyncedIds = <String>{};
    for (final op in catOps) {
      try {
        if (op.opType == 'delete_cluster' || op.opType == 'delete_category') {
          await datasource.deleteCategory(op.recordId);
        } else {
          final rows = await (db.select(db.categoriesTable)
                ..where((t) => t.id.equals(op.recordId)))
              .get();
          if (rows.isNotEmpty) {
            final r = rows.first;
            final base = {
              'id': r.id,
              'name': r.name,
              'sort_order': r.sortOrder,
              'created_at': r.createdAt.toIso8601String(),
              'last_used_at': r.lastUsedAt.toIso8601String(),
              'updated_at': r.updatedAt.toIso8601String(),
            };
            await datasource.upsertCategory(
                {...base, if (r.color != null) 'color': r.color});
            justSyncedIds.add(r.id);
          }
        }
        await db.deletePendingOp(op.id);
      } catch (e) {
        await _reportError(
          'sync_pending_cluster_op',
          e,
          context: {'cluster_id': op.recordId, 'op_type': op.opType},
        );
        continue;
      }
    }

    await _catchUpSync(justSyncedIds);
  }
}
