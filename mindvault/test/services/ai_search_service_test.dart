import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindvault/core/constants/ai_constants.dart';
import 'package:mindvault/core/utils/rate_limiter.dart';
import 'package:mindvault/data/local/database/app_database.dart';
import 'package:mindvault/domain/entities/note.dart';
import 'package:mindvault/services/ai_search_service.dart';
import 'package:mindvault/services/error_log_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Fake backend ──────────────────────────────────────────────────────────────

class _FakeBackend implements AiBackend {
  final String Function(String query) respond;
  int callCount = 0;
  List<({String title, String body})> lastNotes = const [];

  _FakeBackend({String response = 'Test answer.'})
      : respond = ((_) => response);

  _FakeBackend.dynamic(this.respond);

  @override
  Future<String> call({
    required String query,
    required List<({String title, String body})> notes,
  }) async {
    callCount++;
    lastNotes = notes;
    return respond(query);
  }
}

// ── Helper ────────────────────────────────────────────────────────────────────

Note _note({
  String id = 'n1',
  String title = 'My Note',
  String body = 'Note body content',
  bool isPrivate = false,
}) {
  return Note(
    id: id,
    userId: 'user1',
    categoryId: 'cat1',
    title: title,
    body: body,
    isPrivate: isPrivate,
    lastUsedAt: DateTime(2024),
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  );
}

void main() {
  late AppDatabase db;
  late RateLimiter rateLimiter;
  late _FakeBackend fakeBackend;

  AiSearchService makeService({int dailyLimit = 100}) => AiSearchService(
        db: db,
        rateLimiter: rateLimiter,
        backend: fakeBackend,
        dailySearchLimit: dailyLimit,
      );

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    rateLimiter = RateLimiter(prefs);
    fakeBackend = _FakeBackend(response: 'The answer.\nSources: My Note');
  });

  tearDown(() => db.close());

  // ── Empty query ───────────────────────────────────────────────────────────

  group('empty query', () {
    test('yields nothing for blank query', () async {
      final events =
          await makeService().search(query: '   ', notes: [_note()]).toList();
      expect(events, isEmpty);
    });
  });

  // ── Rate limiting ─────────────────────────────────────────────────────────

  group('rate limiting', () {
    test('yields AiRateLimitedEvent when minute limit is saturated', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('rl_minute_tokens', AiConstants.maxRequestsPerMinute);
      await prefs.setInt(
        'rl_minute_reset',
        DateTime.now().add(const Duration(minutes: 1)).millisecondsSinceEpoch ~/
            1000,
      );
      rateLimiter = RateLimiter(prefs);

      final events = await makeService()
          .search(query: 'test query', notes: [_note()]).toList();
      expect(events.first, isA<AiRateLimitedEvent>());
    });

    test('yields AiRateLimitedEvent when daily tier limit is reached',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      // Simulate 5 queries already used today (free tier limit)
      await prefs.setInt('rl_day_tokens', 5);
      await prefs.setInt(
        'rl_day_reset',
        DateTime.now().add(const Duration(hours: 24)).millisecondsSinceEpoch ~/
            1000,
      );
      rateLimiter = RateLimiter(prefs);

      final events = await makeService(dailyLimit: 5)
          .search(query: 'test query', notes: [_note()]).toList();
      expect(events.first, isA<AiRateLimitedEvent>());
    });

    test('pro tier allows more daily searches than free tier', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      // Simulate 5 queries used — free would block, pro should not
      await prefs.setInt('rl_day_tokens', 5);
      await prefs.setInt(
        'rl_day_reset',
        DateTime.now().add(const Duration(hours: 24)).millisecondsSinceEpoch ~/
            1000,
      );
      rateLimiter = RateLimiter(prefs);

      final events = await makeService(dailyLimit: 50).search(
        query: 'test',
        notes: [_note(title: 'Test', body: 'test content')],
      ).toList();
      // Should NOT be rate limited — should reach loading or done
      expect(events.any((e) => e is AiRateLimitedEvent), isFalse);
    });
  });

  // ── No matching notes ─────────────────────────────────────────────────────

  group('fallback context', () {
    test('falls back to recent non-private notes when nothing matches',
        () async {
      final events = await makeService().search(
        query: 'zzzyyyxxx',
        notes: [_note(title: 'Alpha', body: 'Beta')],
      ).toList();
      final done = events.whereType<AiDoneEvent>().first;
      expect(done.answer, equals('The answer.'));
      expect(done.fromCache, isFalse);
      expect(fakeBackend.callCount, equals(1));
      expect(fakeBackend.lastNotes.single.title, equals('Alpha'));
    });

    test('yields done with "no relevant notes" when there is no safe context',
        () async {
      final events = await makeService()
          .search(query: 'zzzyyyxxx', notes: const []).toList();
      final done = events.whereType<AiDoneEvent>().first;
      expect(done.answer, contains('No relevant notes'));
      expect(fakeBackend.callCount, equals(0));
    });

    test('excludes private notes from context', () async {
      final events = await makeService().search(
        query: 'secret',
        notes: [
          _note(title: 'Secret', body: 'secret content', isPrivate: true)
        ],
      ).toList();
      final done = events.whereType<AiDoneEvent>().first;
      expect(done.answer, contains('No relevant notes'));
      expect(fakeBackend.callCount, equals(0));
    });
  });

  // ── Successful search ─────────────────────────────────────────────────────

  group('successful search', () {
    test('yields loading → done for matching notes', () async {
      final events = await makeService().search(
        query: 'flutter',
        notes: [_note(title: 'Flutter Tips', body: 'Use Riverpod')],
      ).toList();
      expect(events.any((e) => e is AiLoadingEvent), isTrue);
      expect(events.last, isA<AiDoneEvent>());
    });

    test('parses Sources line from response', () async {
      fakeBackend = _FakeBackend(response: 'Great answer.\nSources: My Note');
      final events = await makeService().search(
        query: 'test',
        notes: [_note(title: 'My Note', body: 'test content')],
      ).toList();
      final done = events.whereType<AiDoneEvent>().first;
      expect(done.answer, equals('Great answer.'));
      expect(done.citedTitles, contains('My Note'));
    });

    test('response without Sources line returns full text as answer', () async {
      fakeBackend = _FakeBackend(response: 'Answer with no sources.');
      final events = await makeService().search(
        query: 'topic',
        notes: [_note(title: 'Topic', body: 'content about topic')],
      ).toList();
      final done = events.whereType<AiDoneEvent>().first;
      expect(done.answer, equals('Answer with no sources.'));
      expect(done.citedTitles, isEmpty);
    });

    test('records rate limiter usage after successful call', () async {
      await makeService().search(
          query: 'test', notes: [_note(body: 'test content')]).drain<void>();
      expect(await rateLimiter.getMinuteUsage(), equals(1));
    });
  });

  // ── Caching ───────────────────────────────────────────────────────────────

  group('caching', () {
    test('second identical query returns fromCache=true', () async {
      final note = _note(title: 'Cache Test', body: 'cache test content');
      final svc = makeService();

      await svc.search(query: 'cache test', notes: [note]).drain<void>();
      final events2 =
          await svc.search(query: 'cache test', notes: [note]).toList();

      final done = events2.whereType<AiDoneEvent>().first;
      expect(done.fromCache, isTrue);
      expect(fakeBackend.callCount, equals(1));
    });

    test('cache lookup is case-insensitive', () async {
      final note = _note(title: 'Case Test', body: 'about some cases');
      final svc = makeService();

      await svc.search(query: 'cases', notes: [note]).drain<void>();
      final events2 = await svc.search(query: 'Cases', notes: [note]).toList();

      final done = events2.whereType<AiDoneEvent>().first;
      expect(done.fromCache, isTrue);
    });
  });

  // ── Relevance filtering ───────────────────────────────────────────────────

  group('relevance filtering', () {
    test('notes matching query are included; non-matching use fallback context',
        () async {
      final matching = _note(
        id: 'n1',
        title: 'Flutter State Management',
        body: 'Riverpod is great',
      );
      final nonMatching = _note(
        id: 'n2',
        title: 'Grocery List',
        body: 'milk eggs bread',
      );

      final events = await makeService().search(
          query: 'flutter state', notes: [matching, nonMatching]).toList();
      expect(events.last, isA<AiDoneEvent>());

      // With no lexical match, the service sends bounded fallback context to AI.
      final eventsNone = await makeService()
          .search(query: 'quantum physics xyz', notes: [nonMatching]).toList();
      expect(
        eventsNone.whereType<AiDoneEvent>().first.answer,
        equals('The answer.'),
      );
    });

    test('single-character tokens are ignored in scoring', () async {
      final events = await makeService().search(
          query: 'a b', notes: [_note(title: 'A', body: 'a b c')]).toList();
      final done = events.whereType<AiDoneEvent>().first;
      expect(done.answer, contains('No relevant notes'));
    });

    test('fallback keeps only the most recently updated notes', () async {
      final oldNote = _note(
        id: 'old',
        title: 'Old',
        body: 'old body',
      );
      final recentNote = oldNote.copyWith(
        id: 'recent',
        title: 'Recent',
        body: 'recent body',
        updatedAt: DateTime(2025),
      );

      await makeService().search(
          query: 'zzzyyyxxx', notes: [oldNote, recentNote]).drain<void>();

      expect(fakeBackend.lastNotes.first.title, equals('Recent'));
    });
  });

  // ── citedNoteIds ─────────────────────────────────────────────────────────

  group('citedNoteIds', () {
    test('resolved from input notes by title (case-insensitive)', () async {
      fakeBackend = _FakeBackend(response: 'Great answer.\nSources: My Note');
      final events = await makeService().search(
        query: 'test',
        notes: [_note(id: 'note-id-1', title: 'My Note', body: 'test content')],
      ).toList();
      final done = events.whereType<AiDoneEvent>().first;
      expect(done.citedNoteIds, contains('note-id-1'));
    });

    test('noResultAnswer constant contains expected phrase', () {
      expect(AiSearchService.noResultAnswer, contains('No relevant notes'));
    });

    test('no-result path yields empty citedNoteIds', () async {
      final events = await makeService().search(
        query: 'zzzyyyxxx',
        notes: const [],
      ).toList();
      final done = events.whereType<AiDoneEvent>().first;
      expect(done.citedNoteIds, isEmpty);
    });

    test('citedNoteIds empty when response has no Sources line', () async {
      fakeBackend = _FakeBackend(response: 'Answer with no sources.');
      final events = await makeService().search(
        query: 'topic',
        notes: [_note(title: 'Topic', body: 'content about topic')],
      ).toList();
      final done = events.whereType<AiDoneEvent>().first;
      expect(done.citedNoteIds, isEmpty);
    });
  });

  // ── Error handling ────────────────────────────────────────────────────────

  group('error handling', () {
    test('backend exception yields AiErrorEvent', () async {
      fakeBackend =
          _FakeBackend.dynamic((_) => throw Exception('network error'));
      // Override callCount manually isn't needed; we just need the throw
      final svc = AiSearchService(
        db: db,
        rateLimiter: rateLimiter,
        backend: _ThrowingBackend(),
      );
      final events = await svc
          .search(query: 'test', notes: [_note(body: 'test content')]).toList();
      expect(events.last, isA<AiErrorEvent>());
    });

    test('backend exception fires the error logger with ai_search source',
        () async {
      final logger = _RecordingErrorLogger();
      final svc = AiSearchService(
        db: db,
        rateLimiter: rateLimiter,
        backend: _ThrowingBackend(),
        errorLogger: logger,
      );
      await svc.search(
          query: 'test', notes: [_note(body: 'test content')]).drain<void>();
      // The logger is invoked unawaited from the service; flush microtasks so
      // the recorded entry lands before assertions.
      await Future<void>.delayed(Duration.zero);
      expect(logger.entries, hasLength(1));
      expect(logger.entries.first.source, equals('ai_search'));
      expect(logger.entries.first.message, contains('simulated network error'));
    });

    test('successful searches do not invoke the error logger', () async {
      final logger = _RecordingErrorLogger();
      final svc = AiSearchService(
        db: db,
        rateLimiter: rateLimiter,
        backend: fakeBackend,
        errorLogger: logger,
      );
      await svc.search(
          query: 'test', notes: [_note(body: 'test content')]).drain<void>();
      await Future<void>.delayed(Duration.zero);
      expect(logger.entries, isEmpty);
    });
  });
}

class _ThrowingBackend implements AiBackend {
  @override
  Future<String> call({
    required String query,
    required List<({String title, String body})> notes,
  }) async {
    throw Exception('simulated network error');
  }
}

class _RecordingErrorLogger implements ErrorLogger {
  final List<({String source, String message})> entries = [];

  @override
  Future<void> report({required String source, required String message}) async {
    entries.add((source: source, message: message));
  }
}
