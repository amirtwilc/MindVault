import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/remote/supabase/supabase_user_profile_datasource.dart';
import '../../domain/entities/tier_limits.dart';
import 'auth_provider.dart';
import 'ai_search_provider.dart';

final userProfileDatasourceProvider =
    Provider<SupabaseUserProfileDatasource>((ref) {
  return SupabaseUserProfileDatasource(ref.watch(supabaseClientProvider));
});

/// Resolves the current user's TierLimits from Supabase (reads the
/// tier_limits table — single source of truth).
/// Falls back to TierLimits.free() if the user is not logged in or the
/// network is unavailable.
final tierProvider = FutureProvider<TierLimits>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return TierLimits.free();

  try {
    return await ref
        .read(userProfileDatasourceProvider)
        .fetchTierLimits(user.id);
  } catch (_) {
    return TierLimits.free();
  }
});

/// Number of AI searches the current user has made today (local counter).
final aiSearchesTodayProvider = FutureProvider<int>((ref) async {
  return ref.watch(rateLimiterProvider).getDayUsage();
});
