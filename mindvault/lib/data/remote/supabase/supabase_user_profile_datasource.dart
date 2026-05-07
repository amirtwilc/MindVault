import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/supabase_constants.dart';
import '../../../domain/entities/tier_limits.dart';

class SupabaseUserProfileDatasource {
  final SupabaseClient _client;
  SupabaseUserProfileDatasource(this._client);

  /// Fetches the user's tier and its associated limits in a single query via
  /// PostgREST's embedded resource syntax (inner join on tier_limits).
  /// Falls back to [TierLimits.free()] on any error or missing row so the app
  /// always has a valid set of limits.
  Future<TierLimits> fetchTierLimits(String userId) async {
    final res = await _client
        .from(SupabaseConstants.profilesTable)
        .select('tier, tier_limits(*)')
        .eq('id', userId)
        .maybeSingle();

    final tier = res?['tier'] as String? ?? 'free';
    final limits = res?['tier_limits'] as Map<String, dynamic>?;

    if (limits == null) return tierLimitsFromName(tier);

    return TierLimits(
      tier: tier,
      maxNotes: (limits['max_notes'] as num).toInt(),
      maxCategories: (limits['max_categories'] as num).toInt(),
      maxCharsPerNote: (limits['max_chars_per_note'] as num).toInt(),
      aiSearchesPerDay: (limits['ai_searches_per_day'] as num).toInt(),
    );
  }
}
