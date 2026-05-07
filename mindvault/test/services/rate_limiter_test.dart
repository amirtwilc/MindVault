import 'package:flutter_test/flutter_test.dart';
import 'package:mindvault/core/utils/rate_limiter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  late RateLimiter rateLimiter;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    rateLimiter = RateLimiter(prefs);
  });

  group('Initial state', () {
    test('minute usage starts at 0', () async {
      expect(await rateLimiter.getMinuteUsage(), equals(0));
    });

    test('day usage starts at 0', () async {
      expect(await rateLimiter.getDayUsage(), equals(0));
    });
  });

  group('recordUsage', () {
    test('increments all windows by the recorded amount', () async {
      await rateLimiter.recordUsage(100);
      expect(await rateLimiter.getMinuteUsage(), equals(100));
      expect(await rateLimiter.getDayUsage(), equals(100));
    });

    test('accumulates multiple calls', () async {
      await rateLimiter.recordUsage(50);
      await rateLimiter.recordUsage(75);
      expect(await rateLimiter.getMinuteUsage(), equals(125));
    });

    test('windows track their own totals independently', () async {
      await rateLimiter.recordUsage(200);
      expect(await rateLimiter.getMinuteUsage(),
          equals(await rateLimiter.getDayUsage()));
    });
  });

  group('Window reset', () {
    test('expired minute window resets to 0', () async {
      // Simulate expired window: set reset time to the past
      final past = DateTime.now()
              .subtract(const Duration(seconds: 61))
              .millisecondsSinceEpoch ~/
          1000;
      await prefs.setInt('rl_minute_tokens', 999);
      await prefs.setInt('rl_minute_reset', past);

      expect(await rateLimiter.getMinuteUsage(), equals(0));
    });

    test('expired day window resets to 0', () async {
      final past =
          DateTime.now().subtract(const Duration(days: 2)).millisecondsSinceEpoch ~/
              1000;
      await prefs.setInt('rl_day_tokens', 5000);
      await prefs.setInt('rl_day_reset', past);

      expect(await rateLimiter.getDayUsage(), equals(0));
    });

    test('non-expired window retains its value', () async {
      // Set reset time in the future
      final future =
          DateTime.now().add(const Duration(minutes: 1)).millisecondsSinceEpoch ~/
              1000;
      await prefs.setInt('rl_minute_tokens', 300);
      await prefs.setInt('rl_minute_reset', future);

      expect(await rateLimiter.getMinuteUsage(), equals(300));
    });
  });

  group('Reset time accessors', () {
    test('getMinuteResetTime returns null before first use', () {
      expect(rateLimiter.getMinuteResetTime(), isNull);
    });

    test('getMinuteResetTime returns a DateTime after first use', () async {
      await rateLimiter.getMinuteUsage(); // initializes the window
      expect(rateLimiter.getMinuteResetTime(), isA<DateTime>());
    });

    test('getDayResetTime returns a DateTime after first use', () async {
      await rateLimiter.getDayUsage();
      expect(rateLimiter.getDayResetTime(), isA<DateTime>());
    });

    test('reset time is approximately now + window duration', () async {
      await rateLimiter.getMinuteUsage();
      final reset = rateLimiter.getMinuteResetTime()!;
      final expected = DateTime.now().add(const Duration(seconds: 60));
      // Allow 2-second tolerance
      expect(reset.difference(expected).inSeconds.abs(), lessThan(2));
    });
  });
}
