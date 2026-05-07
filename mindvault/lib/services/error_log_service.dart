import 'package:supabase_flutter/supabase_flutter.dart';

/// A best-effort error reporter. Writes a single row to the Supabase
/// `error_logs` table per call so we can spot patterns in production
/// (most importantly: AI search failures).
///
/// All failures are swallowed: no connection, no signed-in user, RLS
/// rejection, the table not existing yet — every path from `report` is
/// fire-and-forget. There is no point logging the logger; the user's
/// flow must never be interrupted by observability.
abstract interface class ErrorLogger {
  /// Records an exception. `source` is a short tag identifying the
  /// component (e.g. `ai_search`); `message` is the exception's
  /// `toString()`. Call sites should NOT include user-private content
  /// (note titles, bodies, queries) in either field — this table is
  /// observability, not analytics.
  Future<void> report({required String source, required String message});
}

class SupabaseErrorLogger implements ErrorLogger {
  final SupabaseClient _client;

  // Hard cap on stored message length so a runaway exception trace
  // can't blow up the row size.
  static const int _maxMessageLen = 2000;

  SupabaseErrorLogger(this._client);

  @override
  Future<void> report({
    required String source,
    required String message,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;
      final trimmed = message.length > _maxMessageLen
          ? '${message.substring(0, _maxMessageLen)}…'
          : message;
      await _client.from('error_logs').insert({
        'user_id': user.id,
        'source': source,
        'message': trimmed,
      });
    } catch (_) {
      // Swallow — offline, RLS rejection, table missing, anything.
      // The user-visible flow must not depend on this succeeding.
    }
  }
}

/// Test/no-op logger.
class NoopErrorLogger implements ErrorLogger {
  const NoopErrorLogger();

  @override
  Future<void> report({required String source, required String message}) async {}
}
