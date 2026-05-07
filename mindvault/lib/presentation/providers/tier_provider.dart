import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/remote/supabase/supabase_user_profile_datasource.dart';
import '../../domain/entities/tier_limits.dart';
import 'auth_provider.dart';
import 'ai_search_provider.dart';

final userProfileDatasourceProvider =
    Provider<SupabaseUserProfileDatasource>((ref) {
  return SupabaseUserProfileDatasource(ref.watch(supabaseClientProvider));
});

/// Resolves the current user's TierLimits from Supabase.
/// Falls back to TierLimits.free() if the user is not logged in or the
/// network is unavailable — so the app always has a valid set of limits.
final tierProvider = FutureProvider<TierLimits>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return TierLimits.free();

  try {
    final tier = await ref
        .read(userProfileDatasourceProvider)
        .fetchTier(user.id);
    return tierLimitsFromName(tier);
  } catch (_) {
    return TierLimits.free();
  }
});

/// Number of AI searches the current user has made today (local counter).
final aiSearchesTodayProvider = FutureProvider<int>((ref) async {
  return ref.watch(rateLimiterProvider).getDayUsage();
});
