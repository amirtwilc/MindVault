import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart';
import '../../services/encryption_service.dart';

final pinAttemptTrackerProvider = Provider<PinAttemptTracker>((ref) {
  return PinAttemptTracker(ref.watch(secureStorageProvider));
});

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
});

final encryptionServiceProvider = Provider<EncryptionService>((ref) {
  return EncryptionService(ref.watch(secureStorageProvider));
});

/// Holds the in-memory AES key once loaded/generated.
final aesKeyProvider = StateProvider<Key?>((ref) => null);

/// True once the user has set up encryption (key exists in storage).
final encryptionReadyProvider = FutureProvider<bool>((ref) async {
  return ref.watch(encryptionServiceProvider).hasKey();
});
