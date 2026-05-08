import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/local/database/note_mappers.dart';
import '../../data/remote/supabase/supabase_notes_datasource.dart';
import '../../data/repositories/note_repository_impl.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import 'analytics_provider.dart';
import 'auth_provider.dart';
import 'database_provider.dart';
import 'encryption_provider.dart';
import 'error_log_provider.dart';

final notesDatasourceProvider = Provider<SupabaseNotesDatasource>((ref) {
  return SupabaseNotesDatasource(ref.watch(supabaseClientProvider));
});

final noteRepositoryProvider = Provider<NoteRepository?>((ref) {
  final user = ref.watch(currentUserProvider);
  final aesKey = ref.watch(aesKeyProvider);
  if (user == null || aesKey == null) return null;

  final repo = NoteRepositoryImpl(
    remote: ref.watch(notesDatasourceProvider),
    local: ref.watch(appDatabaseProvider),
    encryption: ref.watch(encryptionServiceProvider),
    aesKey: aesKey,
    userId: user.id,
    analytics: ref.read(analyticsServiceProvider),
    errorLogger: ref.read(errorLoggerProvider),
  );
  repo.startSync();
  ref.onDispose(repo.stopSync);
  return repo;
});

final notesByCategoryProvider = StreamProvider.family<List<Note>, String>((ref, categoryId) {
  final repo = ref.watch(noteRepositoryProvider);
  if (repo == null) return const Stream.empty();
  return repo.watchNotesByCategory(categoryId);
});

final allNotesProvider = StreamProvider<List<Note>>((ref) {
  final repo = ref.watch(noteRepositoryProvider);
  if (repo == null) return const Stream.empty();
  return repo.watchAllNotes();
});

/// Local-only stream of notes in [categoryId], bypassing the AES-key gate on
/// [noteRepositoryProvider]. Note rows in the local Drift DB are stored as
/// plaintext (encryption is applied only on the wire to Supabase), so the
/// list view does not need the AES key. Used by the Categories home-widget
/// floating window so notes appear as soon as the engine boots, without
/// waiting on `flutter_secure_storage.read()`.
///
/// The AES-key gate on [noteRepositoryProvider] also doubled as an auth gate —
/// no signed-in user → no key → empty stream. We replace that with an explicit
/// [currentUserProvider] check plus a `userId` filter on the SQL query, so
/// residual plaintext rows from a previous session are never rendered after
/// sign-out and a stale widget can't read another user's rows on a shared
/// device.
final notesByCategoryLocalProvider =
    StreamProvider.family<List<Note>, String>((ref, categoryId) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  final db = ref.watch(appDatabaseProvider);
  return db.watchNotesByCategory(categoryId, user.id).map(
        (rows) => rows.map(rowToNote).toList(),
      );
});
