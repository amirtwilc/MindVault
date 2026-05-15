import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/constants/supabase_constants.dart';
import 'presentation/providers/ai_search_provider.dart';

void main() async {
  // Ensure Flutter engine is ready before using plugins like SharedPreferences
  WidgetsFlutterBinding.ensureInitialized();

  // Load local persistent preferences before app startup
  final prefs = await SharedPreferences.getInstance();

  // Initialize Supabase backend and authentication client
  await Supabase.initialize(
    url: SupabaseConstants.url,
    anonKey: SupabaseConstants.anonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  runApp(
    // ProviderScope is Riverpod's dependency injection container
    // Override SharedPreferences provider with the already initialized instance
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MindVaultApp(),
    ),
  );
}
