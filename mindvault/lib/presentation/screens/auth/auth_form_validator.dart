class AuthFormValidator {
  static final RegExp _emailPattern = RegExp(
    r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
  );
  static final RegExp _otpPattern = RegExp(r'^\d{6,8}$');

  static String? emailError(
    String value, {
    String requiredMessage = 'Email is required.',
    String invalidMessage = 'Enter a valid email address.',
  }) {
    final email = value.trim();
    if (email.isEmpty) return requiredMessage;
    if (!_emailPattern.hasMatch(email)) return invalidMessage;
    return null;
  }

  static String? passwordError(
    String value, {
    String requiredMessage = 'Password is required.',
    String tooShortMessage = 'Password must be at least 6 characters.',
  }) {
    if (value.isEmpty) return requiredMessage;
    if (value.length < 6) return tooShortMessage;
    return null;
  }

  static String? otpError(
    String value, {
    String requiredMessage = 'Verification code is required.',
    String invalidMessage = 'Enter the code from your email.',
  }) {
    final otp = value.trim();
    if (otp.isEmpty) return requiredMessage;
    if (!_otpPattern.hasMatch(otp)) return invalidMessage;
    return null;
  }

  static String? confirmPasswordError(
    String password,
    String confirmation, {
    String requiredMessage = 'Please confirm your password.',
    String mismatchMessage = 'Passwords do not match.',
  }) {
    if (confirmation.isEmpty) return requiredMessage;
    if (password != confirmation) return mismatchMessage;
    return null;
  }
}
