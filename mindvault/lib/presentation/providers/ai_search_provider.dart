import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthChangeEvent;

import '../../core/utils/rate_limiter.dart';
import '../../data/local/database/app_database.dart';
import '../../domain/entities/tier_limits.dart';
import '../../services/ai_search_service.dart';
import 'auth_provider.dart';
import 'database_provider.dart';
import 'error_log_provider.dart';
import 'notes_provider.dart';
import 'tier_provider.dart';

// ── Infrastructure ────────────────────────────────────────────────────────────

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override sharedPreferencesProvider in main.dart');
});

final rateLimiterProvider = Provider<RateLimiter>((ref) {
  return RateLimiter(ref.watch(sharedPreferencesProvider));
});

final aiSearchServiceProvider = Provider<AiSearchService>((ref) {
  final tier = ref.watch(tierProvider).valueOrNull ?? TierLimits.free();
  return AiSearchService(
    db: ref.watch(appDatabaseProvider),
    rateLimiter: ref.watch(rateLimiterProvider),
    backend: SupabaseAiBackend(ref.watch(supabaseClientProvider)),
    dailySearchLimit: tier.aiSearchesPerDay,
    errorLogger: ref.watch(errorLoggerProvider),
  );
});

// ── AI history entry ──────────────────────────────────────────────────────────

class AiHistoryEntry {
  final String queryHash;
  final String query;
  final String answer;
  final List<String> citedTitles;
  final List<String> citedNoteIds;
  final DateTime createdAt;

  const AiHistoryEntry({
    required this.queryHash,
    required this.query,
    required this.answer,
    required this.citedTitles,
    required this.citedNoteIds,
    required this.createdAt,
  });

  factory AiHistoryEntry.fromRow(AiSearchHistoryTableData row) {
    return AiHistoryEntry(
      queryHash: row.queryHash,
      query: row.query,
      answer: row.answer,
      citedTitles: (jsonDecode(row.citedTitlesJson) as List).cast<String>(),
      citedNoteIds: (jsonDecode(row.citedNoteIdsJson) as List).cast<String>(),
      createdAt: row.createdAt,
    );
  }
}

final aiSearchHistoryProvider = StreamProvider<List<AiHistoryEntry>>((ref) {
  return ref.watch(appDatabaseProvider).watchHistory().map(
        (rows) => rows.map(AiHistoryEntry.fromRow).toList(),
      );
});

// ── State ─────────────────────────────────────────────────────────────────────
//
// All non-idle states carry the `query` they came from so the search screen
// can repopulate the input box. Without this, switching away and returning
// leaves a result on screen with no visible query.

sealed class AiSearchState {
  const AiSearchState();
}

class AiSearchIdle extends AiSearchState {
  const AiSearchIdle();
}

class AiSearchLoading extends AiSearchState {
  final String query;
  const AiSearchLoading(this.query);
}

class AiSearchSuccess extends AiSearchState {
  final String query;
  final String answer;
  final List<String> citedTitles;
  final List<String> citedNoteIds;
  final bool fromCache;
  const AiSearchSuccess({
    required this.query,
    required this.answer,
    required this.citedTitles,
    required this.citedNoteIds,
    required this.fromCache,
  });
}

class AiSearchRateLimited extends AiSearchState {
  final String query;
  final DateTime? resetAt;
  const AiSearchRateLimited({required this.query, this.resetAt});
}

class AiSearchFailed extends AiSearchState {
  final String query;
  final String message;
  const AiSearchFailed({required this.query, required this.message});
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class AiSearchNotifier extends StateNotifier<AiSearchState> {
  final AiSearchService _service;
  final Ref _ref;

  AiSearchNotifier(this._service, this._ref) : super(const AiSearchIdle());

  void reset() => state = const AiSearchIdle();

  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      state = const AiSearchIdle();
      return;
    }

    final notes = _ref.read(allNotesProvider).valueOrNull ?? [];
    state = AiSearchLoading(trimmed);

    await for (final event in _service.search(query: trimmed, notes: notes)) {
      if (!mounted) return;
      switch (event) {
        case AiRateLimitedEvent(:final resetAt):
          state = AiSearchRateLimited(query: trimmed, resetAt: resetAt);
        case AiLoadingEvent():
          state = AiSearchLoading(trimmed);
        case AiDoneEvent(:final answer, :final citedTitles, :final citedNoteIds, :final fromCache):
          state = AiSearchSuccess(
            query: trimmed,
            answer: answer,
            citedTitles: citedTitles,
            citedNoteIds: citedNoteIds,
            fromCache: fromCache,
          );
          if (!fromCache) _ref.invalidate(aiSearchesTodayProvider);
          // Write to history only when AI found relevant results
          if (citedTitles.isNotEmpty && answer != AiSearchService.noResultAnswer) {
            await _ref.read(appDatabaseProvider).insertHistory(
                  queryHash: AiSearchService.hashQuery(trimmed.toLowerCase()),
                  query: trimmed,
                  answer: answer,
                  citedTitles: citedTitles,
                  citedNoteIds: citedNoteIds,
                );
          }
        case AiErrorEvent(:final message):
          state = AiSearchFailed(query: trimmed, message: message);
      }
    }
  }
}

final aiSearchProvider =
    StateNotifierProvider<AiSearchNotifier, AiSearchState>((ref) {
  return AiSearchNotifier(ref.watch(aiSearchServiceProvider), ref);
});

// Clears AI history when a different user signs in, preventing cross-account
// history leakage. Watches authStateProvider and compares against the last
// stored user ID in SharedPreferences.
final aiHistoryIsolationProvider = Provider<void>((ref) {
  ref.listen(authStateProvider, (_, next) async {
    final event = next.valueOrNull;
    if (event == null) return;
    if (event.event != AuthChangeEvent.signedIn) return;

    final userId = event.session?.user.id;
    if (userId == null) return;

    final prefs = ref.read(sharedPreferencesProvider);
    final lastUserId = prefs.getString('ai_history_last_user_id');

    if (lastUserId != null && lastUserId != userId) {
      await ref.read(appDatabaseProvider).clearAllHistory();
    }
    await prefs.setString('ai_history_last_user_id', userId);
  });
});
