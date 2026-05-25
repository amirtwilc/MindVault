import 'dart:convert';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/remote/supabase/supabase_jots_datasource.dart';
import '../../data/repositories/jot_repository_impl.dart';
import '../../domain/entities/jot.dart';
import '../../domain/repositories/jot_repository.dart';
import '../../services/jot_action_service.dart';
import '../../services/jot_reminder_scheduler_service.dart';
import '../../services/jots_ai_service.dart';
import 'auth_provider.dart';
import 'categories_provider.dart';
import 'database_provider.dart';
import 'encryption_provider.dart';
import 'error_log_provider.dart';
import 'notes_provider.dart';
import 'reminder_provider.dart';
import 'shared_preferences_provider.dart';
import 'tier_provider.dart';

final jotsDatasourceProvider = Provider<SupabaseJotsDatasource>((ref) {
  return SupabaseJotsDatasource(ref.watch(supabaseClientProvider));
});

final jotRepositoryProvider = Provider<JotRepository?>((ref) {
  final user = ref.watch(currentUserProvider);
  final aesKey = ref.watch(aesKeyProvider);
  if (user == null || aesKey == null) return null;

  final repo = JotRepositoryImpl(
    remote: ref.watch(jotsDatasourceProvider),
    local: ref.watch(appDatabaseProvider),
    encryption: ref.watch(encryptionServiceProvider),
    aesKey: aesKey,
    userId: user.id,
    errorLogger: ref.read(errorLoggerProvider),
  );
  repo.startSync();
  ref.onDispose(repo.stopSync);
  return repo;
});

final jotSortOrderProvider =
    StateNotifierProvider<JotSortOrderNotifier, JotSortOrder>((ref) {
  return JotSortOrderNotifier(ref.watch(sharedPreferencesProvider));
});

class JotSortOrderNotifier extends StateNotifier<JotSortOrder> {
  static const _key = 'jots.sort_order';
  final SharedPreferences _prefs;

  JotSortOrderNotifier(this._prefs)
      : super(JotSortOrder.fromStorage(_prefs.getString(_key)));

  Future<void> setOrder(JotSortOrder order) async {
    state = order;
    await _prefs.setString(_key, order.storageValue);
  }
}

final unhandledJotsProvider = StreamProvider<List<Jot>>((ref) {
  final repo = ref.watch(jotRepositoryProvider);
  final sortOrder = ref.watch(jotSortOrderProvider);
  if (repo == null) return const Stream.empty();
  return repo.watchUnhandledJots(sortOrder: sortOrder);
});

final jotReminderSchedulerProvider =
    Provider<JotReminderSchedulerService>((ref) {
  return JotReminderSchedulerService();
});

final jotActionServiceProvider = Provider<JotActionService?>((ref) {
  final jotRepo = ref.watch(jotRepositoryProvider);
  final noteRepo = ref.watch(noteRepositoryProvider);
  final reminderRepo = ref.watch(reminderRepositoryProvider);
  if (jotRepo == null || noteRepo == null || reminderRepo == null) {
    return null;
  }
  return JotActionService(
    jotRepository: jotRepo,
    noteRepository: noteRepo,
    reminderRepository: reminderRepo,
  );
});

final jotsAiQuotaStoreProvider = Provider<JotsAiQuotaStore>((ref) {
  return JotsAiQuotaStore(ref.watch(sharedPreferencesProvider));
});

final jotsAiUsageTodayProvider = FutureProvider<int>((ref) async {
  return ref.watch(jotsAiQuotaStoreProvider).getDayUsage();
});

final jotsAiServiceProvider = Provider<JotsAiService>((ref) {
  return JotsAiService(
    backend: SupabaseJotsAiBackend(ref.watch(supabaseClientProvider)),
    quota: ref.watch(jotsAiQuotaStoreProvider),
  );
});

sealed class JotsAiState {
  const JotsAiState();
}

class JotsAiIdle extends JotsAiState {
  const JotsAiIdle();
}

class JotsAiLoading extends JotsAiState {
  const JotsAiLoading();
}

class JotsAiNoNewThoughts extends JotsAiState {
  const JotsAiNoNewThoughts();
}

class JotsAiRateLimited extends JotsAiState {
  final DateTime? resetAt;
  const JotsAiRateLimited(this.resetAt);
}

class JotsAiSuccess extends JotsAiState {
  final JotsAiRunResult result;
  const JotsAiSuccess(this.result);
}

class JotsAiFailure extends JotsAiState {
  final String message;
  const JotsAiFailure(this.message);
}

final jotsAiControllerProvider =
    StateNotifierProvider<JotsAiController, JotsAiState>((ref) {
  return JotsAiController(ref);
});

class JotsAiController extends StateNotifier<JotsAiState> {
  final Ref _ref;
  JotsAiController(this._ref) : super(const JotsAiIdle());

  Future<void> organize() async {
    final repo = _ref.read(jotRepositoryProvider);
    if (repo == null) return;
    state = const JotsAiLoading();
    try {
      final result = await _ref.read(jotsAiServiceProvider).organize(
            jots: _ref.read(unhandledJotsProvider).valueOrNull ?? [],
            categories: _ref.read(categoriesProvider).valueOrNull ?? [],
            notes: _ref.read(allNotesProvider).valueOrNull ?? [],
            locale: PlatformDispatcher.instance.locale,
          );
      if (result == null) {
        state = const JotsAiNoNewThoughts();
        return;
      }

      final suggestionByJot = {
        for (final suggestion in result.suggestions)
          suggestion.jotId: suggestion
      };
      final now = DateTime.now().toUtc();
      for (final jotId in result.processedJotIds) {
        final suggestion = suggestionByJot[jotId];
        await repo.updateJot(
          id: jotId,
          aiProcessedAt: now,
          aiSuggestionRunId: result.runId,
          aiSuggestionJson:
              suggestion == null ? null : jsonEncode(suggestion.toJson()),
        );
      }
      _ref.invalidate(jotsAiUsageTodayProvider);
      state = JotsAiSuccess(result);
    } on JotsAiQuotaExceeded catch (e) {
      state = JotsAiRateLimited(e.resetAt);
    } catch (e) {
      state = JotsAiFailure(e.toString());
    }
  }

  void reset() => state = const JotsAiIdle();
}
