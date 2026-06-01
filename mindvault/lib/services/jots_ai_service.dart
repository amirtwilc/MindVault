import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/jot_constants.dart';
import '../domain/entities/category.dart';
import '../domain/entities/jot.dart';
import '../domain/entities/note.dart';

class JotsAiQuotaExceeded implements Exception {
  final DateTime? resetAt;
  const JotsAiQuotaExceeded({this.resetAt});
}

class JotsAiBackendException implements Exception {
  final String message;
  final int httpStatus;
  const JotsAiBackendException(this.message, {required this.httpStatus});

  @override
  String toString() => message;
}

abstract interface class JotsAiBackend {
  Future<Map<String, dynamic>> call(Map<String, dynamic> request);
}

class SupabaseJotsAiBackend implements JotsAiBackend {
  final SupabaseClient _client;
  SupabaseJotsAiBackend(this._client);

  @override
  Future<Map<String, dynamic>> call(Map<String, dynamic> request) async {
    final res = await _client.functions.invoke(
      'organize-jots',
      body: request,
    );
    if (res.status == 200) {
      return Map<String, dynamic>.from(res.data as Map);
    }
    final msg = (res.data as Map?)?.containsKey('error') == true
        ? res.data['error'] as String
        : 'Request failed (${res.status})';
    throw JotsAiBackendException(msg, httpStatus: res.status);
  }
}

class JotsAiQuotaStore {
  static const String _tokensKey = 'jots_ai_day_tokens';
  static const String _dateKey = 'jots_ai_day_date';
  static const String _legacyResetKey = 'jots_ai_day_reset';

  final SharedPreferences _prefs;
  JotsAiQuotaStore(this._prefs);

  Future<int> getDayUsage() async => _getUsage();

  Future<void> recordUsage() async {
    _getUsage();
    await _prefs.setInt(_tokensKey, (_prefs.getInt(_tokensKey) ?? 0) + 1);
  }

  DateTime get resetAt => _nextUtcMidnight();

  int _getUsage() {
    final today = _todayUtcKey();
    if (_prefs.getString(_dateKey) != today) {
      _prefs.setInt(_tokensKey, 0);
      _prefs.setString(_dateKey, today);
      _prefs.remove(_legacyResetKey);
      return 0;
    }
    return _prefs.getInt(_tokensKey) ?? 0;
  }

  String _todayUtcKey() =>
      DateTime.now().toUtc().toIso8601String().split('T').first;

  DateTime _nextUtcMidnight() {
    final now = DateTime.now().toUtc();
    return DateTime.utc(now.year, now.month, now.day + 1);
  }
}

class JotsAiRunResult {
  final String runId;
  final int sentCount;
  final bool limitedToThirty;
  final List<JotAiSuggestion> suggestions;
  final List<String> processedJotIds;

  const JotsAiRunResult({
    required this.runId,
    required this.sentCount,
    required this.limitedToThirty,
    required this.suggestions,
    required this.processedJotIds,
  });
}

class JotsAiService {
  final JotsAiBackend _backend;
  final JotsAiQuotaStore _quota;

  JotsAiService({
    required JotsAiBackend backend,
    required JotsAiQuotaStore quota,
  })  : _backend = backend,
        _quota = quota;

  Future<JotsAiRunResult?> organize({
    required List<Jot> jots,
    required List<Category> categories,
    required List<Note> notes,
    Locale? locale,
  }) async {
    final eligible = jots.where((j) => !j.isHandled && !j.wasSentToAi).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    if (eligible.isEmpty) return null;

    final selected = eligible.take(JotConstants.maxAiJotsPerRun).toList();
    final request = _buildRequest(
      jots: selected,
      categories: categories,
      notes: notes,
      locale: locale ?? PlatformDispatcher.instance.locale,
    );
    final Map<String, dynamic> response;
    try {
      response = await _backend.call(request);
    } on JotsAiBackendException catch (e) {
      if (e.httpStatus == 429 || e.message == 'quota_exceeded') {
        throw JotsAiQuotaExceeded(resetAt: _quota.resetAt);
      }
      rethrow;
    }
    await _quota.recordUsage();

    final runId = response['run_id'] as String? ??
        DateTime.now().toUtc().toIso8601String();
    final validSuggestions = _parseSuggestions(
      response,
      selectedJots: selected,
      categories: categories,
      notes: notes,
    );

    return JotsAiRunResult(
      runId: runId,
      sentCount: selected.length,
      limitedToThirty: eligible.length > selected.length,
      suggestions: validSuggestions,
      processedJotIds: selected.map((j) => j.id).toList(),
    );
  }

  Map<String, dynamic> _buildRequest({
    required List<Jot> jots,
    required List<Category> categories,
    required List<Note> notes,
    required Locale locale,
  }) {
    final safeNotes = notes.where((n) => !n.isPrivate).toList()
      ..sort((a, b) {
        final aTime = a.lastOpenedAt ?? a.updatedAt;
        final bTime = b.lastOpenedAt ?? b.updatedAt;
        return bTime.compareTo(aTime);
      });
    return {
      'locale': locale.toLanguageTag(),
      'now': DateTime.now().toUtc().toIso8601String(),
      'local_now': DateTime.now().toIso8601String(),
      'time_zone_offset_minutes': DateTime.now().timeZoneOffset.inMinutes,
      'time_zone_name': DateTime.now().timeZoneName,
      'jots': [
        for (final jot in jots)
          {
            'id': jot.id,
            'text': jot.text,
            'created_at': jot.createdAt.toUtc().toIso8601String(),
          }
      ],
      'categories': [
        for (final category in categories)
          {
            'id': category.id,
            'name': category.name,
          }
      ],
      'notes': [
        for (final note in safeNotes.take(JotConstants.aiNoteContextLimit))
          {
            'id': note.id,
            'title': note.title,
            'category_id': note.categoryId,
            'note_type': note.noteType.storageValue,
          }
      ],
    };
  }

  List<JotAiSuggestion> _parseSuggestions(
    Map<String, dynamic> response, {
    required List<Jot> selectedJots,
    required List<Category> categories,
    required List<Note> notes,
  }) {
    final raw = response['suggestions'];
    if (raw is! List) return const [];
    final jotIds = selectedJots.map((j) => j.id).toSet();
    final categoryIds = categories.map((c) => c.id).toSet();
    final categoryNames = categories.map((c) => c.name.toLowerCase()).toSet();
    final noteIds = notes.where((n) => !n.isPrivate).map((n) => n.id).toSet();
    final result = <JotAiSuggestion>[];
    for (final item in raw) {
      if (item is! Map) continue;
      try {
        final suggestion =
            JotAiSuggestion.fromJson(Map<String, dynamic>.from(item));
        if (!jotIds.contains(suggestion.jotId)) continue;
        if (!suggestion.isHighConfidence) continue;
        if (suggestion.categoryId != null &&
            !categoryIds.contains(suggestion.categoryId)) {
          continue;
        }
        if (suggestion.categoryId == null &&
            suggestion.categoryName != null &&
            !categoryNames.contains(suggestion.categoryName!.toLowerCase())) {
          continue;
        }
        if (suggestion.action == JotSuggestedAction.addToNote &&
            !noteIds.contains(suggestion.noteId)) {
          continue;
        }
        if (suggestion.action == JotSuggestedAction.reminder &&
            suggestion.reminderAt == null) {
          continue;
        }
        if (suggestion.noteType != null &&
            suggestion.noteType != 'text' &&
            suggestion.noteType != 'record' &&
            suggestion.noteType != 'checklist' &&
            suggestion.noteType != 'plan') {
          continue;
        }
        final updatedText = suggestion.updatedText?.trim();
        if (updatedText != null &&
            (updatedText.isEmpty ||
                updatedText.length > JotConstants.maxChars)) {
          continue;
        }
        result.add(suggestion);
      } catch (_) {
        continue;
      }
    }
    return result;
  }
}
