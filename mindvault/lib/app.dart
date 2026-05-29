import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_theme.dart';
import 'domain/entities/jot.dart';
import 'l10n/app_localizations.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/locale_provider.dart';
import 'presentation/providers/notes_provider.dart';
import 'presentation/providers/reminder_provider.dart';
import 'presentation/providers/jots_provider.dart';
import 'presentation/router/app_router.dart';

class MindVaultApp extends ConsumerStatefulWidget {
  const MindVaultApp({super.key});

  @override
  ConsumerState<MindVaultApp> createState() => _MindVaultAppState();
}

class _MindVaultAppState extends ConsumerState<MindVaultApp> {
  StreamSubscription<Uri>? _linkSub;
  Timer? _jotReminderCleanupTimer;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    final appLinks = AppLinks();
    final initial = await appLinks.getInitialLink();
    if (initial != null) _handleDeepLink(initial);
    _linkSub = appLinks.uriLinkStream.listen((uri) async {
      if (_handleDeepLink(uri)) return;
      try {
        // Complete Supabase auth flow using redirect URL from login
        await Supabase.instance.client.auth.getSessionFromUrl(uri);
      } catch (e) {
        // Ignore harmless PKCE sign-out callback issue from Supabase
        if (e is AuthApiException && e.statusCode == '404') return;
        ref.read(deepLinkErrorProvider.notifier).state = e.toString();
      }
    });
  }

  bool _handleDeepLink(Uri uri) {
    if (uri.scheme == 'mindvault' &&
        uri.host == 'reminder' &&
        uri.path == '/note') {
      final noteId = uri.queryParameters['id'];
      if (noteId != null && noteId.isNotEmpty && mounted) {
        ref.read(appRouterProvider).go(Uri(
              path: '/reminder-note',
              queryParameters: {'id': noteId},
            ).toString());
      }
      return true;
    }
    if (uri.scheme == 'mindvault' &&
        uri.host == 'jot' &&
        uri.path == '/reminder') {
      final jotId = uri.queryParameters['id'];
      if (jotId != null && jotId.isNotEmpty && mounted) {
        ref.read(appRouterProvider).go(Uri(
              path: '/jot-reminder',
              queryParameters: {'id': jotId},
            ).toString());
      }
      return true;
    }
    if (uri.scheme == 'mindvault' && uri.host == 'spark-digest') {
      if (mounted) ref.read(appRouterProvider).go('/spark-digest');
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    _jotReminderCleanupTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeProvider);
    ref.listen(activeRemindersProvider, (_, next) async {
      if (!next.hasValue) return;
      final reminders = next.value ?? const [];
      final noteRepo = ref.read(noteRepositoryProvider);
      if (noteRepo == null) return;
      await ref.read(reminderSchedulerProvider).reconcileAll(
            reminders: reminders,
            loadNote: noteRepo.getNoteById,
            untitledFallback: '(untitled)',
            notificationBody: reminderStringsFor(ref.read(localeProvider))
                .reminderNotificationBody,
          );
    });
    ref.listen(unhandledJotsProvider, (_, next) async {
      if (!next.hasValue) return;
      final now = DateTime.now().toUtc();
      final jots = next.value ?? const [];
      await _clearExpiredJotReminders(jots);
      final jotScheduler = ref.read(jotReminderSchedulerProvider);
      final strings = reminderStringsFor(ref.read(localeProvider));
      if (jots.isEmpty) {
        await jotScheduler.cancelDailyDigest();
      } else {
        await jotScheduler.scheduleDailyDigest(
          title: strings.jotDailyDigestTitle,
          body: strings.jotDailyDigestBody,
        );
      }
      final active = jots
          .where(
              (jot) => jot.reminderAt != null && jot.reminderAt!.isAfter(now))
          .toList();
      await jotScheduler.cancelExcept(active.map((jot) => jot.id));
      for (final jot in active) {
        await jotScheduler.schedule(
          jot: jot,
          notificationBody: strings.jotNotificationBody,
        );
      }
      _scheduleNextJotReminderCleanup(jots);
    });
    ref.watch(reminderStartupProvider);

    return MaterialApp.router(
      title: 'MindVault',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
      locale: locale,
      localizationsDelegates: AppStrings.localizationsDelegates,
      supportedLocales: AppStrings.supportedLocales,
      localeResolutionCallback: (device, supported) {
        if (device != null) {
          for (final s in supported) {
            if (s.languageCode == device.languageCode) return s;
          }
        }
        return const Locale('en');
      },
      debugShowCheckedModeBanner: false,
    );
  }

  Future<void> _clearExpiredJotReminders(List<Jot> jots) async {
    final now = DateTime.now().toUtc();
    const clearDelay = Duration(seconds: 10);
    final expired = jots
        .where(
          (jot) =>
              jot.reminderAt != null &&
              jot.reminderAt!.isBefore(now.subtract(clearDelay)),
        )
        .toList();
    final jotRepo = ref.read(jotRepositoryProvider);
    for (final jot in expired) {
      await jotRepo?.clearReminder(jot.id);
    }
  }

  void _scheduleNextJotReminderCleanup(List<Jot> jots) {
    _jotReminderCleanupTimer?.cancel();
    final now = DateTime.now().toUtc();
    DateTime? next;
    for (final jot in jots) {
      final reminderAt = jot.reminderAt;
      if (reminderAt == null || !reminderAt.isAfter(now)) continue;
      if (next == null || reminderAt.isBefore(next)) next = reminderAt;
    }
    if (next == null) return;
    final delay = next.difference(now) + const Duration(seconds: 12);
    _jotReminderCleanupTimer = Timer(delay, () async {
      if (!mounted) return;
      final current = ref.read(unhandledJotsProvider).valueOrNull ?? const [];
      await _clearExpiredJotReminders(current);
      if (mounted) _scheduleNextJotReminderCleanup(current);
    });
  }
}
