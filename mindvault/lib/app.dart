import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/locale_provider.dart';
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
    _linkSub = appLinks.uriLinkStream.listen((uri) async {
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

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeProvider);

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
