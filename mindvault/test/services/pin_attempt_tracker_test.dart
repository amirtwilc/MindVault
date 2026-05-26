import 'package:flutter_test/flutter_test.dart';
import 'package:mindvault/services/encryption_service.dart';

import '../helpers/fake_secure_storage.dart';

void main() {
  late PinAttemptTracker tracker;
  late FakeSecureStorage storage;

  setUp(() {
    storage = FakeSecureStorage();
    tracker = PinAttemptTracker(storage);
  });

  group('PinAttemptTracker', () {
    test('no lockout initially', () async {
      expect(await tracker.getLockoutRemaining(), isNull);
    });

    test('no lockout after fewer than 5 failures', () async {
      for (var i = 0; i < 5; i++) {
        await tracker.recordFailure();
      }
      expect(await tracker.getLockoutRemaining(), isNull);
    });

    test('lockout applied after 6th failure', () async {
      for (var i = 0; i < 6; i++) {
        await tracker.recordFailure();
      }
      final remaining = await tracker.getLockoutRemaining();
      expect(remaining, isNotNull);
      expect(remaining!.inSeconds, greaterThan(0));
    });

    test('lockout duration doubles with each extra failure', () async {
      // First lockout at failure #6
      for (var i = 0; i < 6; i++) await tracker.recordFailure();
      final first = (await tracker.getLockoutRemaining())!.inSeconds;

      // Reset and trigger two extra failures beyond threshold
      storage = FakeSecureStorage();
      tracker = PinAttemptTracker(storage);
      for (var i = 0; i < 7; i++) await tracker.recordFailure();
      final second = (await tracker.getLockoutRemaining())!.inSeconds;

      expect(second, greaterThan(first));
    });

    test('reset clears count and lockout', () async {
      for (var i = 0; i < 6; i++) await tracker.recordFailure();
      expect(await tracker.getLockoutRemaining(), isNotNull);

      await tracker.reset();
      expect(await tracker.getLockoutRemaining(), isNull);

      // After reset, 5 more failures should not lock out
      for (var i = 0; i < 5; i++) await tracker.recordFailure();
      expect(await tracker.getLockoutRemaining(), isNull);
    });

    test('expired lockout returns null', () async {
      // Manually write a past timestamp
      await storage.write(
        key: 'pin_locked_until',
        value: DateTime.now()
            .subtract(const Duration(seconds: 1))
            .toIso8601String(),
      );
      expect(await tracker.getLockoutRemaining(), isNull);
    });
  });
}
