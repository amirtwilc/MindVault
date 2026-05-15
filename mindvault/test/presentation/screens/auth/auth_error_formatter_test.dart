import 'package:flutter_test/flutter_test.dart';
import 'package:mindvault/presentation/screens/auth/auth_error_formatter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  const messages = AuthErrorMessages(
    invalidCredentials: 'friendly invalid credentials',
    emailAlreadyUsed: 'friendly email exists',
    weakPassword: 'friendly weak password',
    emailNotConfirmed: 'friendly email not confirmed',
    invalidOtp: 'friendly invalid otp',
    expiredOtp: 'friendly expired otp',
    rateLimited: 'friendly rate limited',
    networkError: 'friendly network error',
    generic: 'friendly generic error',
  );

  test('maps invalid credentials without leaking raw exception details', () {
    final result = AuthErrorFormatter.friendlyMessage(
      AuthApiException(
        'Invalid login credentials',
        statusCode: '400',
        code: 'invalid_credentials',
      ),
      messages,
    );

    expect(result, 'friendly invalid credentials');
    expect(result, isNot(contains('AuthApiException')));
    expect(result, isNot(contains('statusCode')));
  });

  test('maps Supabase duplicate email errors', () {
    final result = AuthErrorFormatter.friendlyMessage(
      AuthApiException(
        'User already registered',
        statusCode: '422',
        code: 'email_exists',
      ),
      messages,
    );

    expect(result, 'friendly email exists');
  });

  test('maps local duplicate email errors', () {
    final result = AuthErrorFormatter.friendlyMessage(
      Exception('Email is already used'),
      messages,
    );

    expect(result, 'friendly email exists');
  });

  test('maps retryable fetch errors to a network message', () {
    final result = AuthErrorFormatter.friendlyMessage(
      AuthRetryableFetchException(),
      messages,
    );

    expect(result, 'friendly network error');
  });

  test('maps expired otp errors', () {
    final result = AuthErrorFormatter.friendlyMessage(
      AuthApiException(
        'Token has expired',
        statusCode: '403',
        code: 'otp_expired',
      ),
      messages,
    );

    expect(result, 'friendly expired otp');
  });
}
