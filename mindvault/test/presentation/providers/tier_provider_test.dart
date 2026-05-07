import 'package:flutter_test/flutter_test.dart';
import 'package:mindvault/domain/entities/tier_limits.dart';
import 'package:mindvault/presentation/providers/tier_provider.dart';

void main() {
  group('TierLimits factories', () {
    test('free() returns expected limits', () {
      final t = TierLimits.free();
      expect(t.tier, 'free');
      expect(t.maxNotes, 100);
      expect(t.maxCategories, 10);
      expect(t.maxCharsPerNote, 5000);
      expect(t.aiSearchesPerDay, 5);
    });

    test('pro() returns expected limits', () {
      final t = TierLimits.pro();
      expect(t.tier, 'pro');
      expect(t.maxNotes, 1000);
      expect(t.maxCategories, 50);
      expect(t.maxCharsPerNote, 20000);
      expect(t.aiSearchesPerDay, 50);
    });

    test('free limits are strictly less than pro limits', () {
      final f = TierLimits.free();
      final p = TierLimits.pro();
      expect(f.maxNotes, lessThan(p.maxNotes));
      expect(f.maxCategories, lessThan(p.maxCategories));
      expect(f.maxCharsPerNote, lessThan(p.maxCharsPerNote));
      expect(f.aiSearchesPerDay, lessThan(p.aiSearchesPerDay));
    });
  });

  group('tierLimitsFromName', () {
    test('returns pro for "pro"', () {
      expect(tierLimitsFromName('pro'), TierLimits.pro());
    });

    test('returns free for unknown tier', () {
      expect(tierLimitsFromName('unknown'), TierLimits.free());
    });

    test('returns free for empty string', () {
      expect(tierLimitsFromName(''), TierLimits.free());
    });
  });

  group('TierLimits equality', () {
    test('two free() instances are equal', () {
      expect(TierLimits.free(), TierLimits.free());
    });

    test('free and pro are not equal', () {
      expect(TierLimits.free(), isNot(TierLimits.pro()));
    });
  });

  group('TierLimits copyWith', () {
    test('can override individual fields', () {
      final custom = TierLimits.free().copyWith(aiSearchesPerDay: 20);
      expect(custom.aiSearchesPerDay, 20);
      expect(custom.maxNotes, TierLimits.free().maxNotes);
    });
  });
}
