import 'package:flutter_test/flutter_test.dart';
import 'package:mindvault/presentation/screens/auth/auth_form_validator.dart';

void main() {
  group('AuthFormValidator.emailError', () {
    test('requires an email address', () {
      expect(AuthFormValidator.emailError(''), 'Email is required.');
    });

    test('rejects malformed email addresses', () {
      expect(
        AuthFormValidator.emailError('not-an-email'),
        'Enter a valid email address.',
      );
    });

    test('accepts trimmed valid email addresses', () {
      expect(AuthFormValidator.emailError(' user@example.com '), isNull);
    });
  });

  group('AuthFormValidator.passwordError', () {
    test('requires a password', () {
      expect(AuthFormValidator.passwordError(''), 'Password is required.');
    });

    test('requires at least 6 characters', () {
      expect(
        AuthFormValidator.passwordError('12345'),
        'Password must be at least 6 characters.',
      );
    });

    test('accepts passwords with 6 or more characters', () {
      expect(AuthFormValidator.passwordError('123456'), isNull);
    });
  });

  group('AuthFormValidator.otpError', () {
    test('requires a verification code', () {
      expect(
        AuthFormValidator.otpError(''),
        'Verification code is required.',
      );
    });

    test('rejects codes shorter than the supported range', () {
      expect(
        AuthFormValidator.otpError('1234'),
        'Enter the code from your email.',
      );
    });

    test('accepts a valid 6-digit code', () {
      expect(AuthFormValidator.otpError('123456'), isNull);
    });

    test('accepts a valid 8-digit code', () {
      expect(AuthFormValidator.otpError('12345678'), isNull);
    });
  });

  group('AuthFormValidator.confirmPasswordError', () {
    test('requires confirmation', () {
      expect(
        AuthFormValidator.confirmPasswordError('hunter2', ''),
        'Please confirm your password.',
      );
    });

    test('rejects mismatched confirmation', () {
      expect(
        AuthFormValidator.confirmPasswordError('hunter2', 'hunter3'),
        'Passwords do not match.',
      );
    });

    test('accepts matching passwords', () {
      expect(
        AuthFormValidator.confirmPasswordError('hunter2', 'hunter2'),
        isNull,
      );
    });
  });
}
