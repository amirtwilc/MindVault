import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/ai_constants.dart';
import '../core/utils/rate_limiter.dart';
import '../data/local/database/app_database.dart';
import '../domain/entities/note.dart';
import 'error_log_service.dart';

// ── Backend abstraction (injectable for tests) ────────────────────────────────

abstract interface class AiBackend {
  Future<String> call({
    required String query,
    required List<({String title, String body})> notes,
  });
}

class SupabaseAiBackend implements AiBackend {
  final SupabaseClient _client;
  SupabaseAiBackend(this._client);

  @override
  Future<String> call({
    required String query,
    required List<({String title, String body})> notes,
  }) async {
    final res = await _client.functions.invoke(
      'ai-search',
      body: {
        'query': query,
        'notes': notes.map((n) => {'title': n.title, 'body': n.body}).toList(),
      },
    );
    if (res.status == 200) {
      return (res.data as Map)['answer'] as String;
    }
    final msg = (res.data as Map?)?.containsKey('error') == true
        ? res.data['error'] as String
        : 'Request failed (${res.status})';
    throw Exception(msg);
  }
}

// ── Events yielded by AiSearchService.search() ───────────────────────────────

sealed class AiSearchEvent {
  const AiSearchEvent();
}

class AiRateLimitedEvent extends AiSearchEvent {
  final DateTime? resetAt;
  const AiRateLimitedEvent({this.resetAt});
}

class AiLoadingEvent extends AiSearchEvent {
  const AiLoadingEvent();
}

class AiDoneEvent extends AiSearchEvent {
  final String answer;
  final List<String> citedTitles;
  final List<String> citedNoteIds;
  final bool fromCache;
  const AiDoneEvent({
    required this.answer,
    required this.citedTitles,
    required this.citedNoteIds,
    required this.fromCache,
  });
}

class AiErrorEvent extends AiSearchEvent {
  final String message;
  const AiErrorEvent(this.message);
}

// ── Rate limit info ───────────────────────────────────────────────────────────

enum RateLimitStatus { ok, minuteExceeded, dayExceeded }

class RateLimitInfo {
  final RateLimitStatus status;
  final DateTime? resetAt;
  const RateLimitInfo({required this.status, this.resetAt});
}

// ── Service ───────────────────────────────────────────────────────────────────

class AiSearchService {
  static const String noResultAnswer = 'No relevant notes found for your query.';

  final AppDatabase _db;
  final RateLimiter _rateLimiter;
  final AiBackend _backend;
  // Daily limit is tier-specific; injected at construction time.
  final int _dailySearchLimit;
  final ErrorLogger _errorLogger;

  AiSearchService({
    required AppDatabase db,
    required RateLimiter rateLimiter,
    required AiBackend backend,
    int dailySearchLimit = 5, // TierLimits.free().aiSearchesPerDay
    ErrorLogger errorLogger = const NoopErrorLogger(),
  })  : _db = db,
        _rateLimiter = rateLimiter,
        _backend = backend,
        _dailySearchLimit = dailySearchLimit,
        _errorLogger = errorLogger;

  Future<RateLimitInfo> checkRateLimit() async {
    final minute = await _rateLimiter.getMinuteUsage();
    if (minute >= AiConstants.maxRequestsPerMinute) {
      return RateLimitInfo(
        status: RateLimitStatus.minuteExceeded,
        resetAt: _rateLimiter.getMinuteResetTime(),
      );
    }
    final day = await _rateLimiter.getDayUsage();
    if (day >= _dailySearchLimit) {
      return RateLimitInfo(
        status: RateLimitStatus.dayExceeded,
        resetAt: _rateLimiter.getDayResetTime(),
      );
    }
    return const RateLimitInfo(status: RateLimitStatus.ok);
  }

  /// Runs an AI search over [notes] (pre-decrypted) for [query].
  Stream<AiSearchEvent> search({
    required String query,
    required List<Note> notes,
  }) async* {
    final normalized = query.trim();
    if (normalized.isEmpty) return;

    // Cache check first — saves a round trip on repeated queries
    await _db.evictExpiredCache(AiConstants.cacheTtl);
    final cacheKey = _hashQuery(normalized.toLowerCase());
    final cached = await _db.getCachedResponse(cacheKey);
    if (cached != null) {
      final parsed = _parseResponse(cached.response);
      final titleToId = <String, String>{};
      for (final n in notes) {
        titleToId[n.title.toLowerCase()] = n.id;
      }
      final citedNoteIds = parsed.citedTitles
          .map((t) => titleToId[t.toLowerCase()])
          .whereType<String>()
          .toList();
      yield AiDoneEvent(
        answer: parsed.answer,
        citedTitles: parsed.citedTitles,
        citedNoteIds: citedNoteIds,
        fromCache: true,
      );
      return;
    }

    final rl = await checkRateLimit();
    if (rl.status != RateLimitStatus.ok) {
      yield AiRateLimitedEvent(resetAt: rl.resetAt);
      return;
    }

    yield const AiLoadingEvent();

    // In-memory relevance filter (FTS5 indexes ciphertext — not useful here)
    final relevant = _filterRelevant(normalized, notes);
    if (relevant.isEmpty) {
      yield const AiDoneEvent(
        answer: noResultAnswer,
        citedTitles: [],
        citedNoteIds: [],
        fromCache: false,
      );
      return;
    }

    final context = _buildContext(relevant);

    try {
      final answer = await _backend.call(query: normalized, notes: context);
      await _rateLimiter.recordUsage(1);
      await _db.cacheResponse(cacheKey, answer);
      final parsed = _parseResponse(answer);
      final titleToId = <String, String>{};
      for (final n in notes) {
        titleToId[n.title.toLowerCase()] = n.id;
      }
      final citedNoteIds = parsed.citedTitles
          .map((t) => titleToId[t.toLowerCase()])
          .whereType<String>()
          .toList();
      yield AiDoneEvent(
        answer: parsed.answer,
        citedTitles: parsed.citedTitles,
        citedNoteIds: citedNoteIds,
        fromCache: false,
      );
    } catch (e) {
      // Fire-and-forget — the logger swallows its own failures.
      unawaited(
          _errorLogger.report(source: 'ai_search', message: e.toString()));
      yield AiErrorEvent(_friendlyError(e.toString()));
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  List<Note> _filterRelevant(String query, List<Note> notes) {
    final words = query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 1)
        .toList();
    if (words.isEmpty) return [];

    final scored = <({Note note, int score})>[];
    for (final note in notes) {
      if (note.isPrivate) continue;
      final titleLow = note.title.toLowerCase();
      final bodyLow = note.body.toLowerCase();
      int score = 0;
      for (final word in words) {
        if (titleLow.contains(word)) score += 3;
        if (bodyLow.contains(word)) score += 1;
      }
      if (score > 0) scored.add((note: note, score: score));
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    if (scored.isNotEmpty) {
      return scored.take(AiConstants.ftsTopK).map((r) => r.note).toList();
    }

    final fallback = notes.where((note) => !note.isPrivate).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return fallback.take(AiConstants.ftsTopK).toList();
  }

  List<({String title, String body})> _buildContext(List<Note> notes) {
    final context = <({String title, String body})>[];
    int charCount = 0;
    for (final note in notes) {
      if (charCount >= AiConstants.tokenBudget) break;
      final body = note.body.length > AiConstants.noteBodyMaxChars
          ? '${note.body.substring(0, AiConstants.noteBodyMaxChars)}…'
          : note.body;
      context.add((title: note.title, body: body));
      charCount += note.title.length + body.length;
    }
    return context;
  }

  ({String answer, List<String> citedTitles}) _parseResponse(String response) {
    const prefix = 'Sources: ';
    final lines = response.trimRight().split('\n');
    int lastIdx = lines.length - 1;
    while (lastIdx >= 0 && lines[lastIdx].trim().isEmpty) {
      lastIdx--;
    }
    if (lastIdx < 0) return (answer: response, citedTitles: []);
    final lastLine = lines[lastIdx].trim();
    if (lastLine.startsWith(prefix)) {
      final answer = lines.sublist(0, lastIdx).join('\n').trimRight();
      final titles = lastLine
          .substring(prefix.length)
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();
      return (answer: answer, citedTitles: titles);
    }
    return (answer: response, citedTitles: []);
  }

  static String hashQuery(String normalized) {
    final digest = SHA256Digest();
    final hash = digest.process(Uint8List.fromList(utf8.encode(normalized)));
    return base64UrlEncode(hash);
  }

  String _hashQuery(String normalized) => AiSearchService.hashQuery(normalized);

  String _friendlyError(String raw) {
    if (raw.contains('quota_exceeded')) {
      return 'Daily AI limit reached. Try again tomorrow.';
    }
    if (raw.contains('Unauthorized')) {
      return 'Session expired. Please sign in again.';
    }
    if (raw.contains('AI not configured')) {
      return 'AI is not available right now.';
    }
    if (raw.contains('SocketException') || raw.contains('network')) {
      return 'No connection. Check your internet and try again.';
    }
    return 'AI request failed. Please try again.';
  }
}
