import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
