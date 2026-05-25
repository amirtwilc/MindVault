import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/encryption_provider.dart';
import '../../providers/jots_provider.dart';

class JotReminderResolverScreen extends ConsumerStatefulWidget {
  final String jotId;

  const JotReminderResolverScreen({super.key, required this.jotId});

  @override
  ConsumerState<JotReminderResolverScreen> createState() =>
      _JotReminderResolverScreenState();
}

class _JotReminderResolverScreenState
    extends ConsumerState<JotReminderResolverScreen> {
  bool _started = false;
  bool _notFound = false;

  @override
  void didUpdateWidget(covariant JotReminderResolverScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.jotId != widget.jotId) {
      _started = false;
      _notFound = false;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _resolve());
    }
  }

  Future<void> _resolve() async {
    if (widget.jotId.isEmpty) {
      if (mounted) setState(() => _notFound = true);
      return;
    }

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

    final jot = await repo.getJotById(widget.jotId);
    if (!mounted) return;
    if (jot == null) {
      setState(() => _notFound = true);
      return;
    }
    context.go(Uri(
      path: '/home/jots',
      queryParameters: {'highlight': widget.jotId},
    ).toString());
  }

  Future<void> _retryLater() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (mounted) setState(() => _started = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppStrings.of(context);
    ref.watch(authStateProvider);
    ref.watch(aesKeyProvider);
    ref.watch(encryptionReadyProvider);
    ref.watch(jotRepositoryProvider);
    if (!_started && !_notFound) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_started) {
          _started = true;
          _resolve();
        }
      });
    }

    if (_notFound) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l.jotReminderNotFound),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/home/jots'),
                child: Text(l.navJots),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
