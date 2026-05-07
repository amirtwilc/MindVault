import 'package:shared_preferences/shared_preferences.dart';

/// Tracks minute / day request counts in SharedPreferences. Used by
/// `AiSearchService` to enforce client-side AI quotas (the edge function
/// applies its own server-side check).
class RateLimiter {
  static const String _minuteKey = 'rl_minute_tokens';
  static const String _minuteResetKey = 'rl_minute_reset';
  static const String _dayKey = 'rl_day_tokens';
  static const String _dayResetKey = 'rl_day_reset';

  static const int _minuteWindow = 60;
  static const int _dayWindow = 86400;

  final SharedPreferences _prefs;

  RateLimiter(this._prefs);

  Future<int> getMinuteUsage() async =>
      _getUsage(_minuteKey, _minuteResetKey, _minuteWindow);

  Future<int> getDayUsage() async =>
      _getUsage(_dayKey, _dayResetKey, _dayWindow);

  Future<void> recordUsage(int tokens) async {
    await _addTokens(_minuteKey, _minuteResetKey, _minuteWindow, tokens);
    await _addTokens(_dayKey, _dayResetKey, _dayWindow, tokens);
  }

  DateTime? getMinuteResetTime() => _getResetTime(_minuteResetKey);
  DateTime? getDayResetTime() => _getResetTime(_dayResetKey);

  int _getUsage(String tokenKey, String resetKey, int windowSeconds) {
    final reset = _prefs.getInt(resetKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (now > reset) {
      _prefs.setInt(tokenKey, 0);
      _prefs.setInt(resetKey, now + windowSeconds);
      return 0;
    }
    return _prefs.getInt(tokenKey) ?? 0;
  }

  Future<void> _addTokens(
      String tokenKey, String resetKey, int windowSeconds, int tokens) async {
    _getUsage(tokenKey, resetKey, windowSeconds); // ensure window is current
    final current = _prefs.getInt(tokenKey) ?? 0;
    await _prefs.setInt(tokenKey, current + tokens);
  }

  DateTime? _getResetTime(String resetKey) {
    final reset = _prefs.getInt(resetKey);
    if (reset == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(reset * 1000);
  }
}
