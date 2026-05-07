import 'package:freezed_annotation/freezed_annotation.dart';

part 'tier_limits.freezed.dart';

@freezed
class TierLimits with _$TierLimits {
  const factory TierLimits({
    required String tier,
    required int maxNotes,
    required int maxCategories,
    required int maxCharsPerNote,
    required int aiSearchesPerDay,
  }) = _TierLimits;

  // ── Offline fallback values ───────────────────────────────────────────────
  // Used when Supabase is unreachable. The authoritative values live in the
  // `tier_limits` Supabase table and are fetched on every app launch via
  // SupabaseUserProfileDatasource.fetchTierLimits().
  factory TierLimits.free() => const TierLimits(
        tier: 'free',
        maxNotes: 100,
        maxCategories: 10,
        maxCharsPerNote: 5000,
        aiSearchesPerDay: 5,
      );

  factory TierLimits.pro() => const TierLimits(
        tier: 'pro',
        maxNotes: 1000,
        maxCategories: 50,
        maxCharsPerNote: 20000,
        aiSearchesPerDay: 50,
      );
}

TierLimits tierLimitsFromName(String name) => switch (name) {
      'pro' => TierLimits.pro(),
      _ => TierLimits.free(),
    };
