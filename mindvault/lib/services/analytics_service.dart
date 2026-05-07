import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/supabase_constants.dart';

/// Tracks behavioural events (note_created, session_started, etc.) to the
/// Supabase `analytics_events` table for developer-facing observability.
///
/// All calls are fire-and-forget: no exception ever propagates from `track()`.
/// Analytics failures must never affect the user-visible flow.
abstract class AnalyticsService {
  void track(String eventType, {Map<String, dynamic>? metadata});
}

class SupabaseAnalyticsService implements AnalyticsService {
  final SupabaseClient _client;

  const SupabaseAnalyticsService(this._client);

  @override
  void track(String eventType, {Map<String, dynamic>? metadata}) {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;
      _client.from(SupabaseConstants.analyticsEventsTable).insert({
        'user_id': userId,
        'event_type': eventType,
        if (metadata != null) 'metadata': metadata,
      }).then((_) {}, onError: (_) {});
    } catch (_) {
      // Swallow sync errors (network stack not ready, RLS, etc.).
    }
  }
}

/// No-op implementation for tests and pre-auth contexts.
class NoopAnalyticsService implements AnalyticsService {
  const NoopAnalyticsService();

  @override
  void track(String eventType, {Map<String, dynamic>? metadata}) {}
}
