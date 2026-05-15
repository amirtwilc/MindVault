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

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String localeCode,
  }) {
    return _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'locale': localeCode,
      },
    );
  }

  Future<AuthResponse> verifyEmailOtp({
    required String email,
    required String token,
  }) {
    return _client.auth.verifyOTP(
      email: email.trim(),
      token: token.trim(),
      type: OtpType.email,
    );
  }

  Future<ResendResponse> resendSignupOtp({
    required String email,
  }) {
    return _client.auth.resend(
      email: email.trim(),
      type: OtpType.signup,
    );
  }

  Future<void> sendPasswordRecoveryEmail({
    required String email,
  }) {
    return _client.auth.resetPasswordForEmail(email.trim());
  }

  Future<AuthResponse> verifyRecoveryOtp({
    required String email,
    required String token,
  }) {
    return _client.auth.verifyOTP(
      email: email.trim(),
      token: token.trim(),
      type: OtpType.recovery,
    );
  }

  Future<UserResponse> updatePassword({
    required String password,
  }) {
    return _client.auth.updateUser(
      UserAttributes(password: password),
    );
  }

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
