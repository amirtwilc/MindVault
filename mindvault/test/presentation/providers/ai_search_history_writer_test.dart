import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindvault/core/utils/rate_limiter.dart';
import 'package:mindvault/data/local/database/app_database.dart';
import 'package:mindvault/domain/entities/note.dart';
import 'package:mindvault/presentation/providers/ai_search_provider.dart';
import 'package:mindvault/presentation/providers/database_provider.dart';
import 'package:mindvault/presentation/providers/notes_provider.dart';
import 'package:mindvault/services/ai_search_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Fake backend ──────────────────────────────────────────────────────────────

class _FixedBackend implements AiBackend {
  final String response;
  const _FixedBackend(this.response);

  @override
  Future<String> call({
    required String query,
    required List<({String title, String body})> notes,
  }) async =>
      response;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Note _note({String id = 'n1', String title = 'My Note', String body = 'note body'}) {
  final now = DateTime(2025);
  return Note(
    id: id,
    userId: 'u1',
    categoryId: 'c1',
    title: title,
    body: body,
    isPrivate: false,
    lastUsedAt: now,
    createdAt: now,
    updatedAt: now,
  );
}

ProviderContainer _makeContainer({
  required AppDatabase db,
  required AiSearchService service,
  List<Note> notes = const [],
}) {
  return ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      aiSearchServiceProvider.overrideWithValue(service),
      allNotesProvider.overrideWith((ref) => Stream.value(notes)),
    ],
  );
}

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() => db.close());

  Future<AiSearchService> _makeService(AiBackend backend) async {
    final prefs = await SharedPreferences.getInstance();
    return AiSearchService(
      db: db,
      rateLimiter: RateLimiter(prefs),
      backend: backend,
      dailySearchLimit: 100,
    );
  }

  // Prime a provider container and wait for the stream to emit before searching.
  Future<void> _prime(ProviderContainer c) async {
    c.read(allNotesProvider); // subscribe
    await Future<void>.delayed(Duration.zero); // let the stream emit
  }

  test('writes history when AI returns cited titles', () async {
    final note = _note(id: 'n1', title: 'My Note', body: 'test content');
    final svc = await _makeService(const _FixedBackend('The answer.\nSources: My Note'));
    final container = _makeContainer(db: db, service: svc, notes: [note]);
    addTearDown(container.dispose);

    await _prime(container);
    await container.read(aiSearchProvider.notifier).search('my note query');
    await Future<void>.delayed(Duration.zero);

    final history = await db.watchHistory().first;
    expect(history.length, equals(1));
    expect(history.first.query, equals('my note query'));
    expect(history.first.citedTitlesJson, contains('My Note'));
  });

  test('skips history write when no relevant notes (noResultAnswer)', () async {
    // Empty notes list → service short-circuits with noResultAnswer
    final svc = await _makeService(const _FixedBackend('irrelevant'));
    final container = _makeContainer(db: db, service: svc, notes: []);
    addTearDown(container.dispose);

    await _prime(container);
    await container.read(aiSearchProvider.notifier).search('zzzyyyxxx');
    await Future<void>.delayed(Duration.zero);

    final history = await db.watchHistory().first;
    expect(history, isEmpty);
  });

  test('skips history write when response has no cited titles', () async {
    final note = _note(body: 'content about topic');
    final svc = await _makeService(const _FixedBackend('Answer with no sources.'));
    final container = _makeContainer(db: db, service: svc, notes: [note]);
    addTearDown(container.dispose);

    await _prime(container);
    await container.read(aiSearchProvider.notifier).search('topic');
    await Future<void>.delayed(Duration.zero);

    final history = await db.watchHistory().first;
    expect(history, isEmpty);
  });
}
