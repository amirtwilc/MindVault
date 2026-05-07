import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindvault/data/local/database/app_database.dart';
import 'package:mindvault/data/models/category_model.dart';
import 'package:mindvault/data/remote/supabase/supabase_categories_datasource.dart';
import 'package:mindvault/data/remote/supabase/supabase_notes_datasource.dart';
import 'package:mindvault/presentation/providers/analytics_provider.dart';
import 'package:mindvault/presentation/providers/auth_provider.dart';
import 'package:mindvault/presentation/providers/categories_provider.dart';
import 'package:mindvault/presentation/providers/database_provider.dart';
import 'package:mindvault/presentation/providers/notes_provider.dart';
import 'package:mindvault/services/analytics_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockCategoriesDatasource extends Mock implements SupabaseCategoriesDatasource {}
class MockNotesDatasource extends Mock implements SupabaseNotesDatasource {}
class MockRealtimeChannel extends Mock implements RealtimeChannel {}
class MockUser extends Mock implements User {
  @override
  String get id => 'user-1';
}

CategoryModel _model({
  String id = 'cat-1',
  String name = 'Work',
  int sortOrder = 0,
  String? color,
}) {
  final iso = DateTime.now().toUtc().toIso8601String();
  return CategoryModel(
    id: id,
    userId: 'user-1',
    name: name,
    sortOrder: sortOrder,
    lastUsedAt: iso,
    createdAt: iso,
    color: color,
  );
}

void main() {
  late MockCategoriesDatasource remoteCats;
  late MockNotesDatasource remoteNotes;
  late MockRealtimeChannel channel;
  late AppDatabase db;
  late MockUser user;
  late ProviderContainer container;

  setUp(() {
    remoteCats = MockCategoriesDatasource();
    remoteNotes = MockNotesDatasource();
    channel = MockRealtimeChannel();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    user = MockUser();

    when(() => channel.unsubscribe()).thenAnswer((_) async => 'ok');
    when(() => remoteCats.subscribeToCategories(any())).thenReturn(channel);
    when(() => remoteCats.fetchCategories()).thenAnswer((_) async => []);
    when(() => remoteNotes.deleteNotesByCategoryId(any())).thenAnswer((_) async {});

    container = ProviderContainer(overrides: [
      currentUserProvider.overrideWithValue(user),
      appDatabaseProvider.overrideWithValue(db),
      categoriesDatasourceProvider.overrideWithValue(remoteCats),
      notesDatasourceProvider.overrideWithValue(remoteNotes),
      analyticsServiceProvider.overrideWithValue(const NoopAnalyticsService()),
    ]);
  });

  tearDown(() {
    container.dispose();
    db.close();
  });

  Future<List<dynamic>> readCategories() =>
      container.read(categoriesProvider.future);

  // ── build() ───────────────────────────────────────────────────────────────

  group('build()', () {
    test('auto-creates General when Drift and Supabase are both empty', () async {
      final cats = await readCategories();
      expect(cats.length, 1);
      expect(cats.first.name, 'General');
    });

    test('returns existing Drift data immediately before catch-up sync', () async {
      // Pre-populate Drift directly
      final now = DateTime.now().toUtc();
      await db.upsertCategory(CategoriesTableCompanion(
        id: const Value('cat-local'),
        userId: const Value('user-1'),
        name: const Value('Cached'),
        sortOrder: const Value(0),
        color: const Value(null),
        lastUsedAt: Value(now),
        createdAt: Value(now),
      ));

      // Supabase returns empty (simulates offline / cold start)
      when(() => remoteCats.fetchCategories()).thenAnswer((_) async => []);

      // The build result should include the local category.
      // _catchUpSync runs in background and will delete it (Supabase has nothing),
      // but the initial build value must reflect Drift.
      final cats = await readCategories();
      expect(cats.any((c) => c.id == 'cat-local'), isTrue);
    });

    test('subscribes to Realtime on build', () async {
      await readCategories();
      verify(() => remoteCats.subscribeToCategories(any())).called(1);
    });
  });

  // ── _catchUpSync ──────────────────────────────────────────────────────────

  group('_catchUpSync (via build)', () {
    test('upserts remote categories into Drift', () async {
      when(() => remoteCats.fetchCategories())
          .thenAnswer((_) async => [_model(id: 'remote-1', name: 'Remote')]);

      await readCategories();
      // Allow catch-up to complete
      await Future.delayed(const Duration(milliseconds: 50));

      final rows = await db.select(db.categoriesTable).get();
      expect(rows.any((r) => r.id == 'remote-1'), isTrue);
    });

    test('removes Drift rows absent from Supabase', () async {
      // Pre-seed Drift with a category not in Supabase
      final now = DateTime.now().toUtc();
      await db.upsertCategory(CategoriesTableCompanion(
        id: const Value('stale'),
        userId: const Value('user-1'),
        name: const Value('Stale'),
        sortOrder: const Value(0),
        color: const Value(null),
        lastUsedAt: Value(now),
        createdAt: Value(now),
      ));

      when(() => remoteCats.fetchCategories()).thenAnswer((_) async => []);

      await readCategories();
      await Future.delayed(const Duration(milliseconds: 50));

      final rows = await db.select(db.categoriesTable).get();
      expect(rows.any((r) => r.id == 'stale'), isFalse);
    });

    test('preserves Drift color when Supabase returns null color', () async {
      // Pre-seed Drift with a color set locally.
      final now = DateTime.now().toUtc();
      await db.upsertCategory(CategoriesTableCompanion(
        id: const Value('cat-colored'),
        userId: const Value('user-1'),
        name: const Value('Colored'),
        sortOrder: const Value(0),
        color: const Value('#FF5722'),
        lastUsedAt: Value(now),
        createdAt: Value(now),
      ));

      // Supabase returns the category but with null color (column missing / not set).
      when(() => remoteCats.fetchCategories())
          .thenAnswer((_) async => [_model(id: 'cat-colored', name: 'Colored', color: null)]);

      await readCategories();
      await Future.delayed(const Duration(milliseconds: 50));

      final row = await (db.select(db.categoriesTable)
            ..where((t) => t.id.equals('cat-colored')))
          .getSingleOrNull();
      expect(row?.color, equals('#FF5722'));
    });

    test('Supabase color wins when non-null', () async {
      // Pre-seed Drift with one color.
      final now = DateTime.now().toUtc();
      await db.upsertCategory(CategoriesTableCompanion(
        id: const Value('cat-colored'),
        userId: const Value('user-1'),
        name: const Value('Colored'),
        sortOrder: const Value(0),
        color: const Value('#FF5722'),
        lastUsedAt: Value(now),
        createdAt: Value(now),
      ));

      // Supabase returns a different color — it should win.
      when(() => remoteCats.fetchCategories()).thenAnswer((_) async =>
          [_model(id: 'cat-colored', name: 'Colored', color: '#42A5F5')]);

      await readCategories();
      await Future.delayed(const Duration(milliseconds: 50));

      final row = await (db.select(db.categoriesTable)
            ..where((t) => t.id.equals('cat-colored')))
          .getSingleOrNull();
      expect(row?.color, equals('#42A5F5'));
    });

    test('does NOT delete justSyncedIds from Drift', () async {
      // Supabase is empty throughout (simulates propagation delay after offline push)
      when(() => remoteCats.fetchCategories()).thenAnswer((_) async => []);

      // Initialize the provider — initial _catchUpSync({}) runs with empty Supabase.
      // No rows in Drift yet so nothing gets deleted.
      await readCategories();
      await Future.delayed(const Duration(milliseconds: 50));

      // NOW seed Drift (simulates a note created offline after the initial sync).
      final now = DateTime.now().toUtc();
      await db.upsertCategory(CategoriesTableCompanion(
        id: const Value('just-pushed'),
        userId: const Value('user-1'),
        name: const Value('Just Pushed'),
        sortOrder: const Value(0),
        color: const Value(null),
        lastUsedAt: Value(now),
        createdAt: Value(now),
      ));

      // Queue a pending op and make upsertCategory succeed.
      await db.upsertPendingOp('cat_just-pushed', 'upsert_category', 'just-pushed');
      when(() => remoteCats.upsertCategory(any())).thenAnswer((_) async {});

      // syncPendingCategoryOps should push 'just-pushed', add it to justSyncedIds,
      // then call _catchUpSync({'just-pushed'}). Supabase returns [] but the row
      // is in justSyncedIds so it must NOT be deleted from Drift.
      await container.read(categoriesProvider.notifier).syncPendingCategoryOps();
      await Future.delayed(const Duration(milliseconds: 50));

      final rows = await db.select(db.categoriesTable).get();
      expect(rows.any((r) => r.id == 'just-pushed'), isTrue);
    });
  });

  // ── syncPendingCategoryOps ────────────────────────────────────────────────

  group('syncPendingCategoryOps', () {
    test('continues processing remaining ops after a single op fails', () async {
      // Stub General creation so it doesn't queue a stray pending op.
      when(() => remoteCats.insertCategory(any(), any(), id: any(named: 'id')))
          .thenAnswer((_) async => _model());
      await readCategories();
      await Future.delayed(const Duration(milliseconds: 50));

      final now = DateTime.now().toUtc();
      for (final id in ['cat-fail', 'cat-ok']) {
        await db.upsertCategory(CategoriesTableCompanion(
          id: Value(id),
          userId: const Value('user-1'),
          name: Value(id),
          sortOrder: const Value(0),
          color: const Value(null),
          lastUsedAt: Value(now),
          createdAt: Value(now),
        ));
        await db.upsertPendingOp('cat_$id', 'upsert_category', id);
      }

      // First upsert fails, second succeeds.
      var callCount = 0;
      when(() => remoteCats.upsertCategory(any())).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) throw Exception('transient error');
      });

      await container.read(categoriesProvider.notifier).syncPendingCategoryOps();

      final ops = await db.getPendingOps();
      final catOps = ops.where((o) => o.opType == 'upsert_category').toList();
      expect(catOps.length, equals(1),
          reason: 'only the failed op should remain; successful op must be cleared');
      expect(catOps.first.recordId, equals('cat-fail'));
    });
  });

  // ── createCategory ────────────────────────────────────────────────────────

  group('createCategory', () {
    test('appears in state immediately (Drift-first)', () async {
      when(() => remoteCats.insertCategory(any(), any(),
              color: any(named: 'color'), id: any(named: 'id')))
          .thenAnswer((_) async => _model());

      await readCategories(); // initialise
      await container.read(categoriesProvider.notifier).createCategory('New Cat');

      final cats = container.read(categoriesProvider).valueOrNull ?? [];
      expect(cats.any((c) => c.name == 'New Cat'), isTrue);
    });

    test('sort order equals current list length', () async {
      // Pre-seed two non-General categories (General is auto-created, making 3 total).
      when(() => remoteCats.fetchCategories()).thenAnswer((_) async => [
            _model(id: 'a', sortOrder: 0),
            _model(id: 'b', sortOrder: 1),
          ]);

      await readCategories();
      await Future.delayed(const Duration(milliseconds: 50));

      when(() => remoteCats.insertCategory(any(), any(),
              id: any(named: 'id')))
          .thenAnswer((inv) async {
        final order = inv.positionalArguments[1] as int;
        return _model(id: 'c', sortOrder: order);
      });

      await container.read(categoriesProvider.notifier).createCategory('Third');

      final cats = container.read(categoriesProvider).valueOrNull ?? [];
      final third = cats.firstWhere((c) => c.name == 'Third');
      // State has General + A + B = 3 items before Third is added, so sortOrder = 3.
      expect(third.sortOrder, equals(3));
    });

    test('queues pending op when Supabase fails', () async {
      when(() => remoteCats.insertCategory(any(), any(),
              color: any(named: 'color'), id: any(named: 'id')))
          .thenThrow(Exception('offline'));

      await readCategories();
      await container.read(categoriesProvider.notifier).createCategory('Offline Cat');

      final ops = await db.getPendingOps();
      expect(ops.any((o) => o.opType == 'upsert_category'), isTrue);
    });

    test('category persists in Drift even when Supabase fails', () async {
      when(() => remoteCats.insertCategory(any(), any(),
              color: any(named: 'color'), id: any(named: 'id')))
          .thenThrow(Exception('offline'));

      await readCategories();
      await container
          .read(categoriesProvider.notifier)
          .createCategory('Persisted');

      final rows = await db.select(db.categoriesTable).get();
      expect(rows.any((r) => r.name == 'Persisted'), isTrue);
    });
  });

  // ── renameCategory ────────────────────────────────────────────────────────

  group('renameCategory', () {
    setUp(() async {
      when(() => remoteCats.fetchCategories())
          .thenAnswer((_) async => [_model(id: 'cat-1', name: 'Old Name')]);
      await readCategories();
      await Future.delayed(const Duration(milliseconds: 50));
    });

    test('updates name in state immediately', () async {
      when(() => remoteCats.updateCategoryName(any(), any()))
          .thenAnswer((_) async {});

      await container
          .read(categoriesProvider.notifier)
          .renameCategory('cat-1', 'New Name');

      final cats = container.read(categoriesProvider).valueOrNull ?? [];
      expect(cats.firstWhere((c) => c.id == 'cat-1').name, equals('New Name'));
    });

    test('updates Drift', () async {
      when(() => remoteCats.updateCategoryName(any(), any()))
          .thenAnswer((_) async {});

      await container
          .read(categoriesProvider.notifier)
          .renameCategory('cat-1', 'Drifted');

      final row = await (db.select(db.categoriesTable)
            ..where((t) => t.id.equals('cat-1')))
          .getSingleOrNull();
      expect(row?.name, equals('Drifted'));
    });

    test('queues pending op when Supabase fails', () async {
      when(() => remoteCats.updateCategoryName(any(), any()))
          .thenThrow(Exception('offline'));

      await container
          .read(categoriesProvider.notifier)
          .renameCategory('cat-1', 'Offline Rename');

      final ops = await db.getPendingOps();
      expect(ops.any((o) => o.opType == 'upsert_category'), isTrue);
    });
  });

  // ── deleteCategory ────────────────────────────────────────────────────────

  group('deleteCategory', () {
    setUp(() async {
      when(() => remoteCats.fetchCategories())
          .thenAnswer((_) async => [_model()]);
      await readCategories();
      await Future.delayed(const Duration(milliseconds: 50));
    });

    test('removes category from state immediately', () async {
      when(() => remoteCats.deleteCategory(any())).thenAnswer((_) async {});

      await container.read(categoriesProvider.notifier).deleteCategory('cat-1');

      final cats = container.read(categoriesProvider).valueOrNull ?? [];
      expect(cats.any((c) => c.id == 'cat-1'), isFalse);
    });

    test('removes category from Drift', () async {
      when(() => remoteCats.deleteCategory(any())).thenAnswer((_) async {});

      await container.read(categoriesProvider.notifier).deleteCategory('cat-1');

      final rows = await db.select(db.categoriesTable).get();
      expect(rows.any((r) => r.id == 'cat-1'), isFalse);
    });

    test('queues delete_category pending op when Supabase fails', () async {
      when(() => remoteCats.deleteCategory(any()))
          .thenThrow(Exception('offline'));

      await container.read(categoriesProvider.notifier).deleteCategory('cat-1');

      final ops = await db.getPendingOps();
      expect(ops.any((o) => o.opType == 'delete_category'), isTrue);
    });
  });

  // ── reorder ───────────────────────────────────────────────────────────────

  group('reorder', () {
    setUp(() async {
      when(() => remoteCats.fetchCategories()).thenAnswer((_) async => [
            _model(id: 'a', name: 'A', sortOrder: 0),
            _model(id: 'b', name: 'B', sortOrder: 1),
            _model(id: 'c', name: 'C', sortOrder: 2),
          ]);
      await readCategories();
      await Future.delayed(const Duration(milliseconds: 50));
    });

    test('assigns new sort orders matching the supplied order', () async {
      when(() => remoteCats.updateSortOrders(any())).thenAnswer((_) async {});

      await container
          .read(categoriesProvider.notifier)
          .reorder(['c', 'a', 'b']);

      final cats = container.read(categoriesProvider).valueOrNull ?? [];
      expect(cats.firstWhere((c) => c.id == 'c').sortOrder, equals(0));
      expect(cats.firstWhere((c) => c.id == 'a').sortOrder, equals(1));
      expect(cats.firstWhere((c) => c.id == 'b').sortOrder, equals(2));
    });

    test('queues pending ops for all categories when Supabase fails', () async {
      when(() => remoteCats.updateSortOrders(any()))
          .thenThrow(Exception('offline'));

      await container
          .read(categoriesProvider.notifier)
          .reorder(['c', 'a', 'b']);

      // Check only the ops for the reordered categories (General creation op is unrelated).
      final ops = await db.getPendingOps();
      final reorderOps = ops.where((o) =>
          o.opType == 'upsert_category' && {'a', 'b', 'c'}.contains(o.recordId));
      expect(reorderOps.length, equals(3));
    });
  });

  // ── updateCategoryColor ───────────────────────────────────────────────────

  group('updateCategoryColor', () {
    setUp(() async {
      when(() => remoteCats.fetchCategories())
          .thenAnswer((_) async => [_model()]);
      await readCategories();
      await Future.delayed(const Duration(milliseconds: 50));
    });

    test('updates color in state and Drift', () async {
      when(() => remoteCats.updateCategoryColor(any(), any()))
          .thenAnswer((_) async {});

      await container
          .read(categoriesProvider.notifier)
          .updateCategoryColor('cat-1', '#42A5F5');

      final cats = container.read(categoriesProvider).valueOrNull ?? [];
      expect(cats.firstWhere((c) => c.id == 'cat-1').color, equals('#42A5F5'));

      final row = await (db.select(db.categoriesTable)
            ..where((t) => t.id.equals('cat-1')))
          .getSingleOrNull();
      expect(row?.color, equals('#42A5F5'));
    });
  });

  // ── Realtime events ───────────────────────────────────────────────────────

  group('_handleRealtimeEvent', () {
    test('insert event adds category to Drift and state', () async {
      await readCategories();

      // Capture the callback registered with subscribeToCategories
      void Function(bool, Map<String, dynamic>)? captured;
      when(() => remoteCats.subscribeToCategories(any()))
          .thenAnswer((inv) {
        captured = inv.positionalArguments.first
            as void Function(bool, Map<String, dynamic>);
        return channel;
      });

      // Re-initialise to capture the new callback
      container.dispose();
      container = ProviderContainer(overrides: [
        currentUserProvider.overrideWithValue(user),
        appDatabaseProvider.overrideWithValue(db),
        categoriesDatasourceProvider.overrideWithValue(remoteCats),
        notesDatasourceProvider.overrideWithValue(remoteNotes),
      ]);

      when(() => remoteCats.fetchCategories()).thenAnswer((_) async => []);
      await container.read(categoriesProvider.future);

      // Fire a simulated Realtime INSERT event
      final iso = DateTime.now().toUtc().toIso8601String();
      captured?.call(false, {
        'id': 'realtime-cat',
        'user_id': 'user-1',
        'name': 'Realtime',
        'sort_order': 0,
        'color': null,
        'last_used_at': iso,
        'created_at': iso,
      });

      await Future.delayed(const Duration(milliseconds: 50));

      final cats = container.read(categoriesProvider).valueOrNull ?? [];
      expect(cats.any((c) => c.id == 'realtime-cat'), isTrue);
    });

    test('delete event removes category from Drift and state', () async {
      // Pre-seed Drift
      final now = DateTime.now().toUtc();
      await db.upsertCategory(CategoriesTableCompanion(
        id: const Value('to-delete'),
        userId: const Value('user-1'),
        name: const Value('Will Be Deleted'),
        sortOrder: const Value(0),
        color: const Value(null),
        lastUsedAt: Value(now),
        createdAt: Value(now),
      ));

      void Function(bool, Map<String, dynamic>)? captured;
      when(() => remoteCats.subscribeToCategories(any())).thenAnswer((inv) {
        captured = inv.positionalArguments.first
            as void Function(bool, Map<String, dynamic>);
        return channel;
      });

      container.dispose();
      container = ProviderContainer(overrides: [
        currentUserProvider.overrideWithValue(user),
        appDatabaseProvider.overrideWithValue(db),
        categoriesDatasourceProvider.overrideWithValue(remoteCats),
        notesDatasourceProvider.overrideWithValue(remoteNotes),
      ]);

      when(() => remoteCats.fetchCategories())
          .thenAnswer((_) async => [_model(id: 'to-delete')]);
      await container.read(categoriesProvider.future);
      await Future.delayed(const Duration(milliseconds: 50));

      captured?.call(true, {'id': 'to-delete'});
      await Future.delayed(const Duration(milliseconds: 50));

      final cats = container.read(categoriesProvider).valueOrNull ?? [];
      expect(cats.any((c) => c.id == 'to-delete'), isFalse);
    });
  });
}
