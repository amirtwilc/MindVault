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
  /// `toString()`. Optional `context` carries structured metadata
  /// (e.g. `{'http_status': 502}`). Call sites should NOT include
  /// user-private content (note titles, bodies, queries) in any field.
  Future<void> report({
    required String source,
    required String message,
    Map<String, dynamic>? context,
  });
}

class SupabaseErrorLogger implements ErrorLogger {
  final SupabaseClient _client;

  // Hard cap so a runaway exception trace can't blow up the row size.
  static const int _maxMessageLen = 2000;

  SupabaseErrorLogger(this._client);

  @override
  Future<void> report({
    required String source,
    required String message,
    Map<String, dynamic>? context,
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
        if (context != null) 'context': context,
      });
    } catch (_) {
      // Swallow — offline, RLS rejection, table missing, anything.
    }
  }
}

/// Test/no-op logger.
class NoopErrorLogger implements ErrorLogger {
  const NoopErrorLogger();

  @override
  Future<void> report({
    required String source,
    required String message,
    Map<String, dynamic>? context,
  }) async {}
}
