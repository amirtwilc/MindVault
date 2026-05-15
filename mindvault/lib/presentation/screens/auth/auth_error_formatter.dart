import 'package:supabase_flutter/supabase_flutter.dart';

class AuthErrorMessages {
  final String invalidCredentials;
  final String emailAlreadyUsed;
  final String weakPassword;
  final String emailNotConfirmed;
  final String invalidOtp;
  final String expiredOtp;
  final String rateLimited;
  final String networkError;
  final String generic;

  const AuthErrorMessages({
    required this.invalidCredentials,
    required this.emailAlreadyUsed,
    required this.weakPassword,
    required this.emailNotConfirmed,
    required this.invalidOtp,
    required this.expiredOtp,
    required this.rateLimited,
    required this.networkError,
    required this.generic,
  });
}

class AuthErrorFormatter {
  static String friendlyMessage(
    Object error,
    AuthErrorMessages messages,
  ) {
    final rawMessage = error.toString().toLowerCase();

    if (error is AuthException) {
      final code = error.code?.toLowerCase();
      final message = error.message.toLowerCase();

      if (code == 'invalid_credentials' ||
          message.contains('invalid login credentials')) {
        return messages.invalidCredentials;
      }
      if (code == 'email_exists' ||
          code == 'user_already_exists' ||
          message.contains('already registered') ||
          message.contains('already used')) {
        return messages.emailAlreadyUsed;
      }
      if (code == 'weak_password' || error is AuthWeakPasswordException) {
        return messages.weakPassword;
      }
      if (code == 'email_not_confirmed' ||
          message.contains('email not confirmed')) {
        return messages.emailNotConfirmed;
      }
      if (code == 'otp_expired' || message.contains('token has expired')) {
        return messages.expiredOtp;
      }
      if (code == 'invalid_otp' ||
          code == 'otp_disabled' ||
          message.contains('invalid otp') ||
          message.contains('invalid token') ||
          message.contains('token is invalid')) {
        return messages.invalidOtp;
      }
      if (code == 'over_email_send_rate_limit' ||
          code == 'over_request_rate_limit' ||
          error.statusCode == '429') {
        return messages.rateLimited;
      }
      if (error is AuthRetryableFetchException) {
        return messages.networkError;
      }
    }

    if (rawMessage.contains('already used')) {
      return messages.emailAlreadyUsed;
    }

    return messages.generic;
  }
}
