import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/locale_provider.dart';
import 'presentation/providers/notes_provider.dart';
import 'presentation/providers/reminder_provider.dart';
import 'presentation/router/app_router.dart';

class MindVaultApp extends ConsumerStatefulWidget {
  const MindVaultApp({super.key});

  @override
  ConsumerState<MindVaultApp> createState() => _MindVaultAppState();
}

class _MindVaultAppState extends ConsumerState<MindVaultApp> {
  StreamSubscription<Uri>? _linkSub;

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
    return false;
  }

  @override
  void dispose() {
    _linkSub?.cancel();
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
}
