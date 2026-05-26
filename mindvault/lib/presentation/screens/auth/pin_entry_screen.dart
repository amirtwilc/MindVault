import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/encryption_provider.dart';
import '../../../data/remote/supabase/supabase_user_keys_datasource.dart';
import '../../../services/encryption_service.dart';

class PinEntryScreen extends ConsumerStatefulWidget {
  const PinEntryScreen({super.key});

  @override
  ConsumerState<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends ConsumerState<PinEntryScreen> {
  final _pinController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  String _formatLockout(AppStrings l, Duration remaining) {
    final secs = remaining.inSeconds + 1;
    return secs < 60
        ? l.pinLockedSeconds(secs)
        : l.pinLockedMinutes((secs / 60).ceil());
  }

  Future<void> _unlock() async {
    final l = AppStrings.of(context);
    final pin = _pinController.text.trim();
    if (pin.isEmpty) return;

    final tracker = ref.read(pinAttemptTrackerProvider);
    final lockout = await tracker.getLockoutRemaining();
    if (lockout != null) {
      setState(() {
        _error = _formatLockout(l, lockout);
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final client = Supabase.instance.client;
      final keysDatasource = SupabaseUserKeysDatasource(client);
      final record = await keysDatasource.fetchUserKey();

      if (record == null) {
        setState(() {
          _error = l.pinEntryNoKey;
          _loading = false;
        });
        return;
      }

      final encService = ref.read(encryptionServiceProvider);
      final wrapped = WrappedKey(
        wrappedKeyB64: record.wrappedKey,
        saltB64: record.salt,
      );
      final aesKey = encService.unwrapKey(wrapped, pin);
      await encService.storeKey(aesKey);
      ref.read(aesKeyProvider.notifier).state = aesKey;
      await tracker.reset();

      if (mounted) context.go('/home/archive');
    } catch (e) {
      await tracker.recordFailure();
      final lockoutAfter = await tracker.getLockoutRemaining();
      if (mounted) {
        setState(() {
          _error = lockoutAfter != null
              ? _formatLockout(l, lockoutAfter)
              : l.pinEntryIncorrect;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.pinEntryAppBar)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(Icons.lock, size: 56, color: cs.primary),
              const SizedBox(height: 16),
              Text(
                l.pinEntryHeading,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _pinController,
                decoration: InputDecoration(
                  labelText: l.pinEntryLabel,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.pin),
                ),
                obscureText: true,
                keyboardType: TextInputType.number,
                autofocus: true,
                onSubmitted: (_) => _unlock(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: TextStyle(color: cs.error),
                    textAlign: TextAlign.center),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _unlock,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(l.actionUnlock),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
