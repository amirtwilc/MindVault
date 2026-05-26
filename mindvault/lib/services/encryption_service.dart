import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/export.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Tracks PIN unlock failures and enforces progressive lockouts.
/// Failure counts and lockout timestamps are persisted in secure storage
/// so lockouts survive app restarts.
class PinAttemptTracker {
  static const String _countKey = 'pin_attempt_count';
  static const String _lockedUntilKey = 'pin_locked_until';

  // First N failures are shown as plain error messages; failures beyond this
  // trigger a timed lockout that doubles with each additional failure.
  static const int _maxFreeAttempts = 5;
  static const int _baseDelaySeconds = 30;

  final FlutterSecureStorage _storage;

  PinAttemptTracker(this._storage);

  /// Returns the remaining lockout duration, or null if not locked.
  Future<Duration?> getLockoutRemaining() async {
    final raw = await _storage.read(key: _lockedUntilKey);
    if (raw == null) return null;
    final lockedUntil = DateTime.tryParse(raw);
    if (lockedUntil == null) return null;
    final remaining = lockedUntil.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  /// Records a failed attempt, applying a lockout if past the free-attempt threshold.
  Future<void> recordFailure() async {
    final raw = await _storage.read(key: _countKey);
    final count = int.tryParse(raw ?? '0') ?? 0;
    final newCount = count + 1;
    await _storage.write(key: _countKey, value: newCount.toString());
    if (newCount > _maxFreeAttempts) {
      final extra = newCount - _maxFreeAttempts;
      // Each additional failure doubles the lockout: 30s → 60s → 120s → …
      final delaySecs = _baseDelaySeconds * (1 << (extra - 1).clamp(0, 10));
      final until = DateTime.now().add(Duration(seconds: delaySecs));
      await _storage.write(
          key: _lockedUntilKey, value: until.toIso8601String());
    }
  }

  /// Clears the failure count and any active lockout (call on successful unlock).
  Future<void> reset() async {
    await _storage.delete(key: _countKey);
    await _storage.delete(key: _lockedUntilKey);
  }
}

class WrappedKey {
  final String wrappedKeyB64;
  final String saltB64;

  const WrappedKey({required this.wrappedKeyB64, required this.saltB64});
}

class EncryptionService {
  static const String _aesKeyStorageKey = 'mindvault_aes_key';
  static const int _keyLength = 32; // 256-bit
  static const int _pbkdf2Iterations = 100000;
  // GCM security proof is defined for 96-bit (12-byte) nonces. 16-byte IVs
  // are routed through GHASH internally, reducing the security margin.
  static const int _ivLength = 12;
  // Legacy IV length used before the 12-byte migration; kept for decryption
  // fallback so existing encrypted notes remain readable.
  static const int _legacyIvLength = 16;

  final FlutterSecureStorage _secureStorage;

  EncryptionService(this._secureStorage);

  // ── Key management ──────────────────────────────────────────────────────

  /// Generates a new random 256-bit AES key.
  Key generateKey() {
    final random = Random.secure();
    final keyBytes = Uint8List.fromList(
      List.generate(_keyLength, (_) => random.nextInt(256)),
    );
    return Key(keyBytes);
  }

  /// Stores the AES key in secure storage.
  Future<void> storeKey(Key key) async {
    await _secureStorage.write(
      key: _aesKeyStorageKey,
      value: base64Encode(key.bytes),
    );
  }

  /// Loads the AES key from secure storage. Returns null if not found.
  Future<Key?> loadKey() async {
    final stored = await _secureStorage.read(key: _aesKeyStorageKey);
    if (stored == null) return null;
    return Key(base64Decode(stored));
  }

  /// Returns true if an AES key exists in secure storage.
  Future<bool> hasKey() async {
    final stored = await _secureStorage.read(key: _aesKeyStorageKey);
    return stored != null;
  }

  /// Deletes the AES key from secure storage (use on sign-out).
  Future<void> deleteKey() async {
    await _secureStorage.delete(key: _aesKeyStorageKey);
  }

  // ── Key wrapping ─────────────────────────────────────────────────────────

  /// Wraps (encrypts) an AES key using a PIN-derived wrapping key (PBKDF2).
  /// Returns a [WrappedKey] containing base64-encoded wrapped key and salt.
  WrappedKey wrapKey(Key aesKey, String pin) {
    final salt = _randomBytes(32);
    final wrappingKey = _deriveKey(pin, salt);

    final iv = IV(_randomBytes(_ivLength));
    final encrypter = Encrypter(AES(wrappingKey, mode: AESMode.gcm));
    final encrypted = encrypter.encryptBytes(aesKey.bytes, iv: iv);

    // Store IV prepended to ciphertext
    final payload = Uint8List(_ivLength + encrypted.bytes.length);
    payload.setRange(0, _ivLength, iv.bytes);
    payload.setRange(_ivLength, payload.length, encrypted.bytes);

    return WrappedKey(
      wrappedKeyB64: base64Encode(payload),
      saltB64: base64Encode(salt),
    );
  }

  /// Unwraps (decrypts) an AES key using a PIN. Throws on wrong PIN.
  /// Supports both 12-byte (current) and legacy 16-byte IVs.
  Key unwrapKey(WrappedKey wrapped, String pin) {
    final salt = base64Decode(wrapped.saltB64);
    final wrappingKey = _deriveKey(pin, salt);
    final payload = base64Decode(wrapped.wrappedKeyB64);
    final encrypter = Encrypter(AES(wrappingKey, mode: AESMode.gcm));

    // Try current 12-byte IV first; fall back to legacy 16-byte if GCM tag fails.
    for (final ivLen in [_ivLength, _legacyIvLength]) {
      try {
        final iv = IV(Uint8List.fromList(payload.sublist(0, ivLen)));
        final ciphertext =
            Encrypted(Uint8List.fromList(payload.sublist(ivLen)));
        final decryptedBytes = encrypter.decryptBytes(ciphertext, iv: iv);
        return Key(Uint8List.fromList(decryptedBytes));
      } catch (_) {
        continue;
      }
    }
    throw StateError(
        'unwrapKey: GCM authentication failed — wrong PIN or corrupt data');
  }

  // ── Isolate-safe static variants (no platform channels) ─────────────────
  //
  // Use these with compute() to run PBKDF2 on a background isolate so the
  // UI thread stays responsive during the ~2 s key derivation.

  static (String wrappedKeyB64, String saltB64) wrapKeyStatic(
      Uint8List keyBytes, String pin) {
    final salt = _staticRandomBytes(32);
    final wrappingKey = _staticDeriveKey(pin, salt);
    final iv = IV(_staticRandomBytes(_ivLength));
    final encrypter = Encrypter(AES(wrappingKey, mode: AESMode.gcm));
    final encrypted = encrypter.encryptBytes(keyBytes, iv: iv);
    final payload = Uint8List(_ivLength + encrypted.bytes.length);
    payload.setRange(0, _ivLength, iv.bytes);
    payload.setRange(_ivLength, payload.length, encrypted.bytes);
    return (base64Encode(payload), base64Encode(salt));
  }

  static Uint8List unwrapKeyStatic(
      String wrappedKeyB64, String saltB64, String pin) {
    final salt = base64Decode(saltB64);
    final wrappingKey = _staticDeriveKey(pin, salt);
    final payload = base64Decode(wrappedKeyB64);
    final encrypter = Encrypter(AES(wrappingKey, mode: AESMode.gcm));

    for (final ivLen in [_ivLength, _legacyIvLength]) {
      try {
        final iv = IV(Uint8List.fromList(payload.sublist(0, ivLen)));
        final ciphertext =
            Encrypted(Uint8List.fromList(payload.sublist(ivLen)));
        return Uint8List.fromList(encrypter.decryptBytes(ciphertext, iv: iv));
      } catch (_) {
        continue;
      }
    }
    throw StateError(
        'unwrapKeyStatic: GCM authentication failed — wrong PIN or corrupt data');
  }

  static Uint8List _staticRandomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
        List.generate(length, (_) => random.nextInt(256)));
  }

  static Key _staticDeriveKey(String pin, Uint8List salt) {
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, _pbkdf2Iterations, _keyLength));
    return Key(pbkdf2.process(Uint8List.fromList(utf8.encode(pin))));
  }

  // ── Encrypt / Decrypt ────────────────────────────────────────────────────

  /// Encrypts [plaintext] with [key]. Returns Base64(IV + ciphertext).
  String encrypt(String plaintext, Key key) {
    final iv = IV(_randomBytes(_ivLength));
    final encrypter = Encrypter(AES(key, mode: AESMode.gcm));
    final encrypted = encrypter.encrypt(plaintext, iv: iv);

    final payload = Uint8List(_ivLength + encrypted.bytes.length);
    payload.setRange(0, _ivLength, iv.bytes);
    payload.setRange(_ivLength, payload.length, encrypted.bytes);
    return base64Encode(payload);
  }

  /// Decrypts Base64(IV + ciphertext) with [key]. Returns plaintext.
  /// Supports both 12-byte (current) and legacy 16-byte IVs.
  String decrypt(String ciphertext, Key key) {
    final payload = base64Decode(ciphertext);
    final encrypter = Encrypter(AES(key, mode: AESMode.gcm));

    for (final ivLen in [_ivLength, _legacyIvLength]) {
      try {
        final iv = IV(Uint8List.fromList(payload.sublist(0, ivLen)));
        final encrypted = Encrypted(Uint8List.fromList(payload.sublist(ivLen)));
        return encrypter.decrypt(encrypted, iv: iv);
      } catch (_) {
        continue;
      }
    }
    throw StateError(
        'decrypt: GCM authentication failed — wrong key or corrupt ciphertext');
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Uint8List _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List.generate(length, (_) => random.nextInt(256)),
    );
  }

  Key _deriveKey(String pin, Uint8List salt) {
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, _pbkdf2Iterations, _keyLength));
    final keyBytes = pbkdf2.process(Uint8List.fromList(utf8.encode(pin)));
    return Key(keyBytes);
  }
}
