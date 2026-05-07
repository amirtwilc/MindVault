import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/biometric_service.dart';

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

/// True once the user has authenticated this session.
/// Resets to false when the app process is killed (cold start).
final privateNotesUnlockedProvider = StateProvider<bool>((ref) => false);
