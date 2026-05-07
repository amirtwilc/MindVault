import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/remote/supabase/supabase_auth_datasource.dart';

// Expose Supabase client through Riverpod for consistent DI
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authDatasourceProvider = Provider<SupabaseAuthDatasource>((ref) {
  return SupabaseAuthDatasource(ref.watch(supabaseClientProvider));
});

// Listen to auth state changes (sign-in, sign-out, session restore)
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authDatasourceProvider).authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  // Watch authStateProvider so this provider rebuilds on every sign-in/sign-out.
  // Without this, currentUser would be cached forever (supabaseClientProvider
  // never changes) and all downstream providers would use stale user IDs.
  ref.watch(authStateProvider);
  return ref.watch(supabaseClientProvider).auth.currentUser;
});

// Holds the last deep link error so AuthScreen can display it.
final deepLinkErrorProvider = StateProvider<String?>((ref) => null);
