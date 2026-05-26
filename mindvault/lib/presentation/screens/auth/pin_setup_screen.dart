import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/database_provider.dart';
import '../../providers/encryption_provider.dart';
import '../../../core/constants/supabase_constants.dart';
import '../../../data/remote/supabase/supabase_user_keys_datasource.dart';
import 'package:encrypt/encrypt.dart' as enc;
import '../../../services/encryption_service.dart';
import '../../../services/widget_data_service.dart';

// Top-level functions required by compute() — must not be closures.
(String wrappedKeyB64, String saltB64) _wrapKeyCompute(
    (Uint8List keyBytes, String pin) args) {
  final (keyBytes, pin) = args;
  return EncryptionService.wrapKeyStatic(keyBytes, pin);
}

Uint8List _unwrapKeyCompute(
    (String wrappedKeyB64, String saltB64, String pin) args) {
  final (wrappedKeyB64, saltB64, pin) = args;
  return EncryptionService.unwrapKeyStatic(wrappedKeyB64, saltB64, pin);
}

enum _Mode { loading, recovery, setup }

class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;
  String? _error;
  _Mode _mode = _Mode.loading;
  UserKeyRecord? _existingKey;

  @override
  void initState() {
    super.initState();
    _checkExistingKey();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingKey() async {
    try {
      final client = Supabase.instance.client;
      final keysDatasource = SupabaseUserKeysDatasource(client);
      final existing = await keysDatasource.fetchUserKey();
      if (mounted) {
        setState(() {
          _existingKey = existing;
          _mode = existing != null ? _Mode.recovery : _Mode.setup;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _mode = _Mode.setup);
    }
  }

  // Ensures a row exists in `profiles` for the current user.
  // The DB trigger creates it on first sign-up, but may be absent for users
  // who signed up before the trigger existed or whose auth row pre-dates it.
  Future<void> _ensureProfile() async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser!.id;
    try {
      await client.from(SupabaseConstants.profilesTable).insert({'id': userId});
    } on PostgrestException catch (e) {
      if (e.code != '23505')
        rethrow; // 23505 = unique_violation: profile already exists
    }
  }

  String _formatLockout(AppStrings l, Duration remaining) {
    final secs = remaining.inSeconds + 1;
    return secs < 60
        ? l.pinLockedSeconds(secs)
        : l.pinLockedMinutes((secs / 60).ceil());
  }

  Future<void> _recover() async {
    final l = AppStrings.of(context);
    final pin = _pinController.text.trim();
    if (pin.length < 4) {
      setState(() => _error = l.pinTooShort);
      return;
    }

    final tracker = ref.read(pinAttemptTrackerProvider);
    final lockout = await tracker.getLockoutRemaining();
    if (lockout != null) {
      setState(() => _error = _formatLockout(l, lockout));
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Run PBKDF2 on a background isolate so the spinner paints immediately.
      final keyBytes = await compute(
        _unwrapKeyCompute,
        (_existingKey!.wrappedKey, _existingKey!.salt, pin),
      );
      final encService = ref.read(encryptionServiceProvider);
      final aesKey = enc.Key(keyBytes);
      await _ensureProfile();
      await encService.storeKey(aesKey);
      ref.read(aesKeyProvider.notifier).state = aesKey;
      await tracker.reset();
      ref.invalidate(encryptionReadyProvider);
    } catch (e) {
      await tracker.recordFailure();
      final lockoutAfter = await tracker.getLockoutRemaining();
      if (mounted) {
        setState(() {
          if (lockoutAfter != null) {
            _error = _formatLockout(l, lockoutAfter);
          } else if (e is PostgrestException) {
            _error = l.pinServerError(e.message);
          } else {
            _error = l.pinRecoverError;
          }
          _loading = false;
        });
      }
    }
  }

  Future<void> _confirmStartFresh() async {
    final l = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.pinStartFreshTitle),
        content: Text(l.pinStartFreshBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text(l.actionStartFresh),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() {
        _mode = _Mode.setup;
        _pinController.clear();
        _confirmController.clear();
        _error = null;
      });
    }
  }

  Future<void> _signOut() async {
    await ref.read(encryptionServiceProvider).deleteKey();
    ref.read(aesKeyProvider.notifier).state = null;
    ref.invalidate(encryptionReadyProvider);
    await WidgetDataService().clearWidget();
    await ref.read(authDatasourceProvider).signOut();
  }

  Future<void> _setup() async {
    final l = AppStrings.of(context);
    final pin = _pinController.text.trim();
    final confirm = _confirmController.text.trim();

    if (pin.length < 4) {
      setState(() => _error = l.pinTooShort);
      return;
    }
    if (pin != confirm) {
      setState(() => _error = l.pinMismatch);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // "Start fresh" path: wipe locally cached plaintext notes and any
      // pending ops that were encrypted with the old key.
      if (_existingKey != null) {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId != null) {
          final db = ref.read(appDatabaseProvider);
          await db.deleteAllUserNotes(userId);
          await db.deleteAllPendingOps();
        }
      }

      final encService = ref.read(encryptionServiceProvider);
      final aesKey = encService.generateKey();

      // Run PBKDF2 on a background isolate so the spinner paints immediately.
      final (wrappedKeyB64, saltB64) = await compute(
        _wrapKeyCompute,
        (Uint8List.fromList(aesKey.bytes), pin),
      );

      await _ensureProfile();

      final client = Supabase.instance.client;
      final keysDatasource = SupabaseUserKeysDatasource(client);
      await keysDatasource.upsertUserKey(
        wrappedKey: wrappedKeyB64,
        salt: saltB64,
      );

      await encService.storeKey(aesKey);
      ref.read(aesKeyProvider.notifier).state = aesKey;
      ref.invalidate(encryptionReadyProvider);
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e is PostgrestException
              ? l.pinServerError(e.message)
              : l.pinSetupError;
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppStrings.of(context);

    if (_mode == _Mode.loading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: cs.primary),
        ),
      );
    }

    final isRecovery = _mode == _Mode.recovery;

    return Scaffold(
      appBar: AppBar(
          title: Text(isRecovery ? l.pinRecoveryAppBar : l.pinSetupAppBar)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                isRecovery ? Icons.lock_open_outlined : Icons.lock_outline,
                size: 56,
                color: cs.primary,
              ),
              const SizedBox(height: 16),
              Text(
                isRecovery ? l.pinRecoveryHeading : l.pinSetupHeading,
                style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isRecovery ? l.pinRecoveryBody : l.pinSetupBody,
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _pinController,
                decoration: InputDecoration(
                  labelText: l.pinLabel,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.pin),
                ),
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 8,
              ),
              if (!isRecovery) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmController,
                  decoration: InputDecoration(
                    labelText: l.pinConfirmLabel,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.pin_outlined),
                  ),
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 8,
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: TextStyle(color: cs.error),
                    textAlign: TextAlign.center),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : (isRecovery ? _recover : _setup),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isRecovery
                        ? l.actionRecoverContinue
                        : l.actionSetupContinue),
              ),
              const SizedBox(height: 16),
              Text(
                isRecovery ? l.pinRecoveryDisclaimer : l.pinSetupDisclaimer,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              if (isRecovery) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _loading ? null : _confirmStartFresh,
                  child: Text(
                    l.pinForgot,
                    style: tt.bodySmall?.copyWith(color: cs.error),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              TextButton(
                onPressed: _loading ? null : _signOut,
                child: Text(
                  l.pinSignOut,
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
