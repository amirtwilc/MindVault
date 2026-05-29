import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/encryption_provider.dart';
import '../../providers/jots_provider.dart';

class SparkDigestResolverScreen extends ConsumerStatefulWidget {
  const SparkDigestResolverScreen({super.key});

  @override
  ConsumerState<SparkDigestResolverScreen> createState() =>
      _SparkDigestResolverScreenState();
}

class _SparkDigestResolverScreenState
    extends ConsumerState<SparkDigestResolverScreen> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _resolve());
    }
  }

  Future<void> _resolve() async {
    final authState = ref.read(authStateProvider);
    if (authState.isLoading) {
      await _retryLater();
      return;
    }
    if (ref.read(currentUserProvider) == null) {
      if (mounted) context.go('/auth');
      return;
    }

    var repo = ref.read(jotRepositoryProvider);
    if (repo == null) {
      final storedKey = await ref.read(encryptionServiceProvider).loadKey();
      if (!mounted) return;
      if (storedKey != null) {
        ref.read(aesKeyProvider.notifier).state = storedKey;
        repo = ref.read(jotRepositoryProvider);
      }
    }

    if (repo == null) {
      final encryptionReady = ref.read(encryptionReadyProvider).valueOrNull;
      if (encryptionReady == true) {
        if (mounted) context.go('/pin-entry');
        return;
      }
      await _retryLater();
      return;
    }

    ref.invalidate(unhandledJotsProvider);
    if (mounted) context.go('/home/sparks');
  }

  Future<void> _retryLater() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (mounted) setState(() => _started = false);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authStateProvider);
    ref.watch(aesKeyProvider);
    ref.watch(encryptionReadyProvider);
    ref.watch(jotRepositoryProvider);
    if (!_started) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_started) {
          _started = true;
          _resolve();
        }
      });
    }

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
