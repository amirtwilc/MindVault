import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/analytics_service.dart';
import 'auth_provider.dart';

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return SupabaseAnalyticsService(ref.watch(supabaseClientProvider));
});
