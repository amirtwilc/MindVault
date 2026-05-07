import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/supabase_constants.dart';

class SupabaseUserProfileDatasource {
  final SupabaseClient _client;
  SupabaseUserProfileDatasource(this._client);

  /// Returns the user's tier ('free' or 'pro'). Falls back to 'free' when the
  /// profile row is missing — the on-signup trigger should populate it, but
  /// pre-trigger users or transient errors must not lock anyone out.
  Future<String> fetchTier(String userId) async {
    final res = await _client
        .from(SupabaseConstants.profilesTable)
        .select('tier')
        .eq('id', userId)
        .maybeSingle();
    return res?['tier'] as String? ?? 'free';
  }
}
