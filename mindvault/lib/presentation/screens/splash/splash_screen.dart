import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../l10n/app_localizations.dart';
import '../../../presentation/providers/encryption_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    _navigate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      context.go('/auth');
      return;
    }

    // Load the AES key so noteRepositoryProvider is ready at home.
    final key = await ref.read(encryptionServiceProvider).loadKey();
    if (key != null && mounted) {
      ref.read(aesKeyProvider.notifier).state = key;
    }

    if (mounted) context.go('/home/all-notes');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppStrings.of(context);

    return Scaffold(
      backgroundColor: cs.surface,
      body: FadeTransition(
        opacity: _fade,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo.png',
                width: 180,
                height: 180,
              ),
              const SizedBox(height: 20),
              Text(
                'MindVault',
                style: tt.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l.splashTagline,
                style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 64),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l.splashLoading,
                style: tt.bodySmall?.copyWith(color: cs.outlineVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
