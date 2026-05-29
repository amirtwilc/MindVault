import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/jots_provider.dart';
import 'auth_error_formatter.dart';
import 'auth_form_validator.dart';

// Toggle for exposing email auth on the screen.
//
// Set this to `true` to restore the email auth UI without re-implementing
// anything:
// 1. The sign-in/create-account form will reappear on the auth screen.
// 2. "Forgot password" will become reachable from the main auth view again.
// 3. OTP verification and password reset flows already remain implemented
//    below, so no extra wiring is needed.
const bool _showEmailAuthOptions = false;

enum _AuthView {
  signIn,
  forgotPasswordRequest,
  verifySignupOtp,
  verifyRecoveryOtp,
  setNewPassword,
}

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _signInFormKey = GlobalKey<FormState>();
  final _forgotPasswordFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  final _newPasswordFormKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _emailLoading = false;
  bool _googleLoading = false;
  bool _creatingAccount = false;
  bool _passwordVisible = false;
  bool _newPasswordVisible = false;
  bool _confirmPasswordVisible = false;
  String? _error;
  String? _successMessage;
  String? _pendingEmail;
  _AuthView _view = _AuthView.signIn;

  bool get _loading => _emailLoading || _googleLoading;
  bool get _isDefaultAuthView => _view == _AuthView.signIn;

  Future<void> _submitEmailAuth() async {
    if (!_signInFormKey.currentState!.validate()) return;

    setState(() {
      _emailLoading = true;
      _error = null;
      _successMessage = null;
    });
    ref.read(deepLinkErrorProvider.notifier).state = null;

    try {
      final datasource = ref.read(authDatasourceProvider);
      if (_creatingAccount) {
        final localeCode = Localizations.localeOf(context).languageCode;
        final response = await datasource.signUpWithEmail(
          email: _emailController.text,
          password: _passwordController.text,
          localeCode: localeCode,
        );
        if (response.user != null &&
            response.user!.identities != null &&
            response.user!.identities!.isEmpty) {
          throw Exception('Email is already used');
        }
        if (mounted && response.session == null) {
          setState(() {
            _pendingEmail = _emailController.text.trim();
            _otpController.clear();
            _view = _AuthView.verifySignupOtp;
            _successMessage = AppStrings.of(context).authCheckEmailOtp;
          });
        }
      } else {
        await datasource.signInWithEmail(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = _formatError(e, context));
    } finally {
      if (mounted) setState(() => _emailLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _googleLoading = true;
      _error = null;
      _successMessage = null;
    });
    ref.read(deepLinkErrorProvider.notifier).state = null;
    try {
      final datasource = ref.read(authDatasourceProvider);
      await datasource.signInWithGoogle();
    } catch (e) {
      if (mounted) setState(() => _error = _formatError(e, context));
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _verifySignupOtp() async {
    if (!_otpFormKey.currentState!.validate() || _pendingEmail == null) return;

    setState(() {
      _emailLoading = true;
      _error = null;
      _successMessage = null;
    });

    try {
      await ref.read(authDatasourceProvider).verifyEmailOtp(
            email: _pendingEmail!,
            token: _otpController.text,
          );
    } catch (e) {
      if (mounted) setState(() => _error = _formatError(e, context));
    } finally {
      if (mounted) setState(() => _emailLoading = false);
    }
  }

  Future<void> _resendSignupOtp() async {
    if (_pendingEmail == null) return;

    setState(() {
      _emailLoading = true;
      _error = null;
      _successMessage = null;
    });

    try {
      await ref.read(authDatasourceProvider).resendSignupOtp(
            email: _pendingEmail!,
          );
      if (mounted) {
        setState(() {
          _successMessage = AppStrings.of(context).authOtpResent;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = _formatError(e, context));
    } finally {
      if (mounted) setState(() => _emailLoading = false);
    }
  }

  Future<void> _sendPasswordRecoveryEmail() async {
    if (!_forgotPasswordFormKey.currentState!.validate()) return;

    setState(() {
      _emailLoading = true;
      _error = null;
      _successMessage = null;
    });

    try {
      await ref.read(authDatasourceProvider).sendPasswordRecoveryEmail(
            email: _emailController.text,
          );
      if (mounted) {
        setState(() {
          _pendingEmail = _emailController.text.trim();
          _otpController.clear();
          _view = _AuthView.verifyRecoveryOtp;
          _successMessage = AppStrings.of(context).authRecoveryCodeSent;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = _formatError(e, context));
    } finally {
      if (mounted) setState(() => _emailLoading = false);
    }
  }

  Future<void> _resendRecoveryOtp() async {
    if (_pendingEmail == null) return;

    setState(() {
      _emailLoading = true;
      _error = null;
      _successMessage = null;
    });

    try {
      await ref.read(authDatasourceProvider).sendPasswordRecoveryEmail(
            email: _pendingEmail!,
          );
      if (mounted) {
        setState(() {
          _successMessage = AppStrings.of(context).authRecoveryCodeResent;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = _formatError(e, context));
    } finally {
      if (mounted) setState(() => _emailLoading = false);
    }
  }

  Future<void> _verifyRecoveryOtp() async {
    if (!_otpFormKey.currentState!.validate() || _pendingEmail == null) return;

    setState(() {
      _emailLoading = true;
      _error = null;
      _successMessage = null;
    });

    try {
      await ref.read(authDatasourceProvider).verifyRecoveryOtp(
            email: _pendingEmail!,
            token: _otpController.text,
          );
      if (mounted) {
        setState(() {
          _view = _AuthView.setNewPassword;
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = _formatError(e, context));
    } finally {
      if (mounted) setState(() => _emailLoading = false);
    }
  }

  Future<void> _updatePassword() async {
    if (!_newPasswordFormKey.currentState!.validate()) return;

    setState(() {
      _emailLoading = true;
      _error = null;
      _successMessage = null;
    });

    try {
      await ref.read(authDatasourceProvider).updatePassword(
            password: _newPasswordController.text,
          );
      if (mounted) {
        setState(() {
          _successMessage = AppStrings.of(context).authPasswordUpdated;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = _formatError(e, context));
    } finally {
      if (mounted) setState(() => _emailLoading = false);
    }
  }

  Future<void> _returnToSignIn({bool signOutRecoverySession = false}) async {
    if (signOutRecoverySession &&
        ref.read(supabaseClientProvider).auth.currentSession != null) {
      await ref.read(jotReminderSchedulerProvider).cancelDailyDigest();
      await ref.read(authDatasourceProvider).signOut();
    }

    if (!mounted) return;
    setState(() {
      _view = _AuthView.signIn;
      _creatingAccount = false;
      _otpController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      _error = null;
      _successMessage = null;
      _pendingEmail = null;
    });
  }

  String _formatError(Object error, BuildContext context) {
    final l = AppStrings.of(context);
    return AuthErrorFormatter.friendlyMessage(
      error,
      AuthErrorMessages(
        invalidCredentials: l.authInvalidCredentials,
        emailAlreadyUsed: l.authEmailAlreadyUsed,
        weakPassword: l.authWeakPassword,
        emailNotConfirmed: l.authEmailNotConfirmed,
        invalidOtp: l.authInvalidOtp,
        expiredOtp: l.authExpiredOtp,
        rateLimited: l.authRateLimited,
        networkError: l.authNetworkError,
        generic: l.authGenericError,
      ),
    );
  }

  void _toggleMode() {
    setState(() {
      _creatingAccount = !_creatingAccount;
      _error = null;
      _successMessage = null;
    });
  }

  void _openForgotPassword() {
    setState(() {
      _view = _AuthView.forgotPasswordRequest;
      _creatingAccount = false;
      _error = null;
      _successMessage = null;
      _otpController.clear();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppStrings.of(context);
    final deepLinkError = ref.watch(deepLinkErrorProvider);
    final authState = ref.watch(authStateProvider).valueOrNull;

    if (authState?.event == AuthChangeEvent.passwordRecovery &&
        _view != _AuthView.setNewPassword) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _view = _AuthView.setNewPassword;
          _error = null;
          _successMessage = null;
        });
      });
    }

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Spacer(flex: 2),
                      Image.asset(
                        'assets/images/logo.png',
                        width: 120,
                        height: 120,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l.appBrand,
                        style: tt.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _title(l),
                        style: tt.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_isDefaultAuthView) ...[
                        const SizedBox(height: 8),
                        Text(
                          l.authIntroBody,
                          style: tt.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const Spacer(flex: 3),
                      if (_error != null ||
                          deepLinkError != null ||
                          _successMessage != null) ...[
                        _AuthMessage(
                          message: deepLinkError ?? _error ?? _successMessage!,
                          isSuccess: _successMessage != null &&
                              _error == null &&
                              deepLinkError == null,
                        ),
                        const SizedBox(height: 16),
                      ],
                      ..._buildContent(context, l, tt, cs),
                      const SizedBox(height: 24),
                      Text(
                        l.authDisclaimer,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildContent(
    BuildContext context,
    AppStrings l,
    TextTheme tt,
    ColorScheme cs,
  ) {
    switch (_view) {
      case _AuthView.signIn:
        return _buildSignInContent(l, tt, cs);
      case _AuthView.forgotPasswordRequest:
        return _buildForgotPasswordContent(l);
      case _AuthView.verifySignupOtp:
        return _buildVerifyOtpContent(
          l: l,
          primaryLabel: l.authVerifyEmailCode,
          onPrimary: _verifySignupOtp,
          onResend: _resendSignupOtp,
          onBack: _returnToSignIn,
          helperText: l.authOtpHelper,
        );
      case _AuthView.verifyRecoveryOtp:
        return _buildVerifyOtpContent(
          l: l,
          primaryLabel: l.authVerifyRecoveryCode,
          onPrimary: _verifyRecoveryOtp,
          onResend: _resendRecoveryOtp,
          onBack: _returnToSignIn,
          helperText: l.authRecoveryOtpHelper,
        );
      case _AuthView.setNewPassword:
        return _buildNewPasswordContent(l);
    }
  }

  List<Widget> _buildSignInContent(
    AppStrings l,
    TextTheme tt,
    ColorScheme cs,
  ) {
    final widgets = <Widget>[
      FilledButton.icon(
        onPressed: _loading ? null : _signInWithGoogle,
        icon: _googleLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.login),
        label: Text(_googleLoading ? l.authSigningIn : l.authSignInGoogle),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    ];

    if (!_showEmailAuthOptions) {
      return widgets;
    }

    widgets.addAll([
      const SizedBox(height: 16),
      Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              l.authOr,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
      const SizedBox(height: 16),
      Form(
        key: _signInFormKey,
        child: Column(
          children: [
            _EmailField(
              controller: _emailController,
              enabled: !_loading,
              label: l.authEmailLabel,
              requiredMessage: l.authEmailRequired,
              invalidMessage: l.authEmailInvalid,
            ),
            const SizedBox(height: 12),
            _PasswordField(
              controller: _passwordController,
              enabled: !_loading,
              label: l.authPasswordLabel,
              visible: _passwordVisible,
              requiredMessage: l.authPasswordRequired,
              tooShortMessage: l.authPasswordTooShort,
              onToggleVisibility: () {
                setState(() => _passwordVisible = !_passwordVisible);
              },
              onFieldSubmitted: (_) {
                if (!_loading) _submitEmailAuth();
              },
            ),
          ],
        ),
      ),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: _loading ? null : _openForgotPassword,
          child: Text(l.authForgotPassword),
        ),
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: _loading ? null : _submitEmailAuth,
        icon: _emailLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(_creatingAccount ? Icons.person_add_alt_1 : Icons.login),
        label: Text(
          _emailLoading
              ? l.authSigningIn
              : _creatingAccount
                  ? l.authCreateAccount
                  : l.authSignInEmail,
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      TextButton(
        onPressed: _loading ? null : _toggleMode,
        child: Text(
          _creatingAccount ? l.authHaveAccount : l.authNeedAccount,
        ),
      ),
    ]);

    return widgets;
  }

  List<Widget> _buildForgotPasswordContent(AppStrings l) {
    return [
      Form(
        key: _forgotPasswordFormKey,
        child: _EmailField(
          controller: _emailController,
          enabled: !_loading,
          label: l.authEmailLabel,
          requiredMessage: l.authEmailRequired,
          invalidMessage: l.authEmailInvalid,
        ),
      ),
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: _loading ? null : _sendPasswordRecoveryEmail,
        icon: _emailLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.mark_email_read_outlined),
        label: Text(
          _emailLoading ? l.authSendingCode : l.authSendRecoveryCode,
        ),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      TextButton(
        onPressed: _loading ? null : _returnToSignIn,
        child: Text(l.authBackToSignIn),
      ),
    ];
  }

  List<Widget> _buildVerifyOtpContent({
    required AppStrings l,
    required String primaryLabel,
    required Future<void> Function() onPrimary,
    required Future<void> Function() onResend,
    required Future<void> Function() onBack,
    required String helperText,
  }) {
    return [
      Text(
        _pendingEmail ?? '',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const SizedBox(height: 8),
      Text(
        helperText,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 16),
      Form(
        key: _otpFormKey,
        child: TextFormField(
          controller: _otpController,
          enabled: !_loading,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.oneTimeCode],
          decoration: InputDecoration(
            labelText: l.authOtpLabel,
            prefixIcon: const Icon(Icons.password_outlined),
          ),
          validator: (value) => AuthFormValidator.otpError(
            value ?? '',
            requiredMessage: l.authOtpRequired,
            invalidMessage: l.authOtpInvalidFormat,
          ),
          onFieldSubmitted: (_) {
            if (!_loading) onPrimary();
          },
        ),
      ),
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: _loading ? null : onPrimary,
        icon: _emailLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.verified_outlined),
        label: Text(_emailLoading ? l.authVerifyingCode : primaryLabel),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      TextButton(
        onPressed: _loading ? null : onResend,
        child: Text(l.authResendCode),
      ),
      TextButton(
        onPressed: _loading ? null : () => onBack(),
        child: Text(l.authBackToSignIn),
      ),
    ];
  }

  List<Widget> _buildNewPasswordContent(AppStrings l) {
    return [
      Text(
        l.authSetNewPasswordBody,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 16),
      Form(
        key: _newPasswordFormKey,
        child: Column(
          children: [
            _PasswordField(
              controller: _newPasswordController,
              enabled: !_loading,
              label: l.authNewPasswordLabel,
              visible: _newPasswordVisible,
              requiredMessage: l.authPasswordRequired,
              tooShortMessage: l.authPasswordTooShort,
              onToggleVisibility: () {
                setState(() => _newPasswordVisible = !_newPasswordVisible);
              },
            ),
            const SizedBox(height: 12),
            _PasswordField(
              controller: _confirmPasswordController,
              enabled: !_loading,
              label: l.authConfirmPasswordLabel,
              visible: _confirmPasswordVisible,
              requiredMessage: l.authConfirmPasswordRequired,
              tooShortMessage: l.authPasswordTooShort,
              validatorOverride: (value) =>
                  AuthFormValidator.confirmPasswordError(
                _newPasswordController.text,
                value ?? '',
                requiredMessage: l.authConfirmPasswordRequired,
                mismatchMessage: l.authPasswordsDoNotMatch,
              ),
              onToggleVisibility: () {
                setState(
                  () => _confirmPasswordVisible = !_confirmPasswordVisible,
                );
              },
              onFieldSubmitted: (_) {
                if (!_loading) _updatePassword();
              },
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: _loading ? null : _updatePassword,
        icon: _emailLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.lock_reset),
        label: Text(
          _emailLoading ? l.authUpdatingPassword : l.authUpdatePassword,
        ),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      TextButton(
        onPressed: _loading
            ? null
            : () => _returnToSignIn(signOutRecoverySession: true),
        child: Text(l.authCancelRecovery),
      ),
    ];
  }

  String _title(AppStrings l) {
    switch (_view) {
      case _AuthView.signIn:
        return l.authSubtitle;
      case _AuthView.forgotPasswordRequest:
        return l.authForgotPasswordTitle;
      case _AuthView.verifySignupOtp:
        return l.authVerifyEmailTitle;
      case _AuthView.verifyRecoveryOtp:
        return l.authVerifyRecoveryTitle;
      case _AuthView.setNewPassword:
        return l.authSetNewPasswordTitle;
    }
  }
}

class _EmailField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final String label;
  final String requiredMessage;
  final String invalidMessage;

  const _EmailField({
    required this.controller,
    required this.enabled,
    required this.label,
    required this.requiredMessage,
    required this.invalidMessage,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.email],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.email_outlined),
      ),
      validator: (value) => AuthFormValidator.emailError(
        value ?? '',
        requiredMessage: requiredMessage,
        invalidMessage: invalidMessage,
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final String label;
  final bool visible;
  final String requiredMessage;
  final String tooShortMessage;
  final VoidCallback onToggleVisibility;
  final ValueChanged<String>? onFieldSubmitted;
  final String? Function(String?)? validatorOverride;

  const _PasswordField({
    required this.controller,
    required this.enabled,
    required this.label,
    required this.visible,
    required this.requiredMessage,
    required this.tooShortMessage,
    required this.onToggleVisibility,
    this.onFieldSubmitted,
    this.validatorOverride,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: !visible,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.password],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          onPressed: onToggleVisibility,
          icon: Icon(
            visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          ),
        ),
      ),
      validator: validatorOverride ??
          (value) => AuthFormValidator.passwordError(
                value ?? '',
                requiredMessage: requiredMessage,
                tooShortMessage: tooShortMessage,
              ),
      onFieldSubmitted: onFieldSubmitted,
    );
  }
}

class _AuthMessage extends StatelessWidget {
  final String message;
  final bool isSuccess;

  const _AuthMessage({
    required this.message,
    required this.isSuccess,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSuccess ? cs.primaryContainer : cs.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: isSuccess ? cs.onPrimaryContainer : cs.onErrorContainer,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
