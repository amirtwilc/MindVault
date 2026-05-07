import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/error_log_service.dart';
import 'auth_provider.dart';

/// Single shared logger instance. Implementation always wraps the active
/// Supabase client; failures are swallowed so consumers can call without
/// guarding for connectivity or auth.
final errorLoggerProvider = Provider<ErrorLogger>((ref) {
  return SupabaseErrorLogger(ref.watch(supabaseClientProvider));
});
