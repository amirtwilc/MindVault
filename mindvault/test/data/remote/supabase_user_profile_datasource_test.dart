import 'package:flutter_test/flutter_test.dart';
import 'package:mindvault/data/remote/supabase/supabase_user_profile_datasource.dart';
import 'package:mindvault/domain/entities/tier_limits.dart';

void main() {
  group('SupabaseUserProfileDatasource.parseTierLimitsResponse', () {
    test('null response → free fallback', () {
      final result = SupabaseUserProfileDatasource.parseTierLimitsResponse(null);
      expect(result, TierLimits.free());
    });

    test('response with no tier_limits row → falls back via tierLimitsFromName', () {
      final result = SupabaseUserProfileDatasource.parseTierLimitsResponse({
        'tier': 'pro',
        'tier_limits': null,
      });
      expect(result, TierLimits.pro());
    });

    test('missing tier field → defaults tier to free', () {
      final result = SupabaseUserProfileDatasource.parseTierLimitsResponse({
        'tier_limits': null,
      });
      expect(result, TierLimits.free());
    });

    test('full limits map → parses all fields correctly', () {
      final result = SupabaseUserProfileDatasource.parseTierLimitsResponse({
        'tier': 'pro',
        'tier_limits': {
          'max_notes': 500,
          'max_categories': 25,
          'max_chars_per_note': 10000,
          'ai_searches_per_day': 20,
        },
      });
      expect(result.tier, 'pro');
      expect(result.maxNotes, 500);
      expect(result.maxCategories, 25);
      expect(result.maxCharsPerNote, 10000);
      expect(result.aiSearchesPerDay, 20);
    });

    test('numeric fields returned as double → toInt() coerces correctly', () {
      final result = SupabaseUserProfileDatasource.parseTierLimitsResponse({
        'tier': 'free',
        'tier_limits': {
          'max_notes': 100.0,
          'max_categories': 10.0,
          'max_chars_per_note': 5000.0,
          'ai_searches_per_day': 5.0,
        },
      });
      expect(result, TierLimits.free());
    });

    test('unknown tier with no limits row → falls back to free', () {
      final result = SupabaseUserProfileDatasource.parseTierLimitsResponse({
        'tier': 'enterprise',
        'tier_limits': null,
      });
      expect(result, TierLimits.free());
    });
  });
}
