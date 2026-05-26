import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/encryption_provider.dart';
import '../../providers/notes_provider.dart';

class ReminderNoteResolverScreen extends ConsumerStatefulWidget {
  final String noteId;

  const ReminderNoteResolverScreen({super.key, required this.noteId});

  @override
  ConsumerState<ReminderNoteResolverScreen> createState() =>
      _ReminderNoteResolverScreenState();
}

class _ReminderNoteResolverScreenState
    extends ConsumerState<ReminderNoteResolverScreen> {
  bool _started = false;
  bool _notFound = false;

  @override
  void didUpdateWidget(covariant ReminderNoteResolverScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.noteId != widget.noteId) {
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
    if (widget.noteId.isEmpty) {
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

    var repo = ref.read(noteRepositoryProvider);
    if (repo == null) {
      final storedKey = await ref.read(encryptionServiceProvider).loadKey();
      if (!mounted) return;
      if (storedKey != null) {
        ref.read(aesKeyProvider.notifier).state = storedKey;
        repo = ref.read(noteRepositoryProvider);
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
    final note = await repo.getNoteById(widget.noteId);
    if (!mounted) return;
    if (note == null) {
      setState(() => _notFound = true);
      return;
    }
    context.go(Uri(
      path: '/home/clusters/${note.categoryId}/edit/${note.id}',
      queryParameters: {'fromReminder': 'true'},
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
    ref.watch(noteRepositoryProvider);
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
              Text(l.reminderNoteNotFound),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/home/archive'),
                child: Text(l.navAllNotes),
              ),
            ],
          ),
        ),
      );
    }
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
