import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/supabase_constants.dart';

Future<void> ensureSupabaseProfile(SupabaseClient client) async {
  final userId = client.auth.currentUser?.id;
  if (userId == null) {
    throw StateError('Supabase profile bootstrap: no authenticated user');
  }

  try {
    await client.from(SupabaseConstants.profilesTable).insert({'id': userId});
  } on PostgrestException catch (e) {
    if (e.code != '23505') rethrow;
  }
}
