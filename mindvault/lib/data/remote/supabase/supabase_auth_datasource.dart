import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/supabase_constants.dart';

class SupabaseAuthDatasource {
  final SupabaseClient _client;
  final GoogleSignIn _googleSignIn;

  SupabaseAuthDatasource(this._client)
      : _googleSignIn = GoogleSignIn(
          serverClientId: SupabaseConstants.googleWebClientId,
        );

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<void> signInWithGoogle() async {
    // Make sure no stale session is cached, so the account picker always shows.
    await _googleSignIn.signOut();

    final account = await _googleSignIn.signIn();
    if (account == null) {
      // User dismissed the account picker — silent return, no error.
      return;
    }

    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null) {
      throw Exception(
        'Google sign-in did not return an ID token. '
        'Verify googleWebClientId in supabase_constants.dart and that the '
        'Android OAuth client SHA-1 matches the APK signing certificate.',
      );
    }

    await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: auth.accessToken,
    );
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Non-fatal: Supabase sign-out below is what matters for app state.
    }
    await _client.auth.signOut();
  }
}
