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

  // ── Tier limit values ────────────────────────────────────────────────────────
  // IMPORTANT: When you change any number here, you MUST also update the
  // matching `TIER_LIMITS` constant at the top of
  // `supabase/functions/ai-search/index.ts` and redeploy the edge function.
  // The client enforces limits locally; the server enforces them authoritatively.
  // Both must agree or users will hit unexpected 429s / bypass client-side guards.
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
