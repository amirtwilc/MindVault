import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindvault/services/encryption_service.dart';

import '../helpers/fake_secure_storage.dart';

/// Produces a ciphertext using the legacy 16-byte IV so we can verify
/// the backward-compatible decrypt path still works after the migration.
String _encryptLegacy(String plaintext, Key key) {
  const legacyIvLen = 16;
  final random = Random.secure();
  final ivBytes =
      Uint8List.fromList(List.generate(legacyIvLen, (_) => random.nextInt(256)));
  final iv = IV(ivBytes);
  final encrypter = Encrypter(AES(key, mode: AESMode.gcm));
  final encrypted = encrypter.encrypt(plaintext, iv: iv);
  final payload = Uint8List(legacyIvLen + encrypted.bytes.length);
  payload.setRange(0, legacyIvLen, ivBytes);
  payload.setRange(legacyIvLen, payload.length, encrypted.bytes);
  return base64Encode(payload);
}

void main() {
  late EncryptionService service;
  late FakeSecureStorage storage;

  setUp(() {
    storage = FakeSecureStorage();
    service = EncryptionService(storage);
  });

  group('Key generation', () {
    test('generateKey produces a 32-byte key', () {
      final key = service.generateKey();
      expect(key.bytes.length, equals(32));
    });

    test('each generateKey call returns unique bytes', () {
      final k1 = service.generateKey();
      final k2 = service.generateKey();
      expect(k1.bytes, isNot(equals(k2.bytes)));
    });
  });

  group('Key storage', () {
    test('storeKey + loadKey round-trip preserves bytes', () async {
      final key = service.generateKey();
      await service.storeKey(key);
      final loaded = await service.loadKey();
      expect(loaded, isNotNull);
      expect(loaded!.bytes, equals(key.bytes));
    });

    test('hasKey returns false before storing', () async {
      expect(await service.hasKey(), isFalse);
    });

    test('hasKey returns true after storing', () async {
      await service.storeKey(service.generateKey());
      expect(await service.hasKey(), isTrue);
    });

    test('deleteKey removes the key', () async {
      await service.storeKey(service.generateKey());
      await service.deleteKey();
      expect(await service.hasKey(), isFalse);
      expect(await service.loadKey(), isNull);
    });

    test('loadKey returns null when nothing stored', () async {
      expect(await service.loadKey(), isNull);
    });
  });

  group('Encrypt / Decrypt', () {
    late Key key;

    setUp(() => key = service.generateKey());

    test('encrypt + decrypt round-trip returns original plaintext', () {
      const plaintext = 'Hello, MindVault!';
      final cipher = service.encrypt(plaintext, key);
      expect(service.decrypt(cipher, key), equals(plaintext));
    });

    test('encrypting the same text twice gives different ciphertexts (random IV)', () {
      const plaintext = 'same text';
      final c1 = service.encrypt(plaintext, key);
      final c2 = service.encrypt(plaintext, key);
      expect(c1, isNot(equals(c2)));
    });

    test('ciphertext is Base64-encoded', () {
      final cipher = service.encrypt('test', key);
      expect(() => RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(cipher), returnsNormally);
    });

    test('decrypting with wrong key throws', () {
      final wrongKey = service.generateKey();
      final cipher = service.encrypt('secret', key);
      expect(() => service.decrypt(cipher, wrongKey), throwsA(anything));
    });

    test('encrypts and decrypts empty string', () {
      final cipher = service.encrypt('', key);
      expect(service.decrypt(cipher, key), equals(''));
    });

    test('encrypts and decrypts unicode text', () {
      const text = 'مرحبا 🔐 日本語';
      final cipher = service.encrypt(text, key);
      expect(service.decrypt(cipher, key), equals(text));
    });
  });

  group('Legacy IV backward compatibility', () {
    late Key key;

    setUp(() => key = service.generateKey());

    test('decrypt handles legacy 16-byte IV ciphertext', () {
      const plaintext = 'legacy note content';
      final legacyCipher = _encryptLegacy(plaintext, key);
      expect(service.decrypt(legacyCipher, key), equals(plaintext));
    });

    test('new encrypt uses 12-byte IV (shorter base64 than legacy)', () {
      const plaintext = 'same text';
      final newCipher = service.encrypt(plaintext, key);
      final legacyCipher = _encryptLegacy(plaintext, key);
      // New payload = 12 IV + ciphertext; legacy = 16 IV + ciphertext.
      // Base64 length difference reflects the 4-byte IV difference.
      final newBytes = base64Decode(newCipher).length;
      final legacyBytes = base64Decode(legacyCipher).length;
      expect(newBytes, equals(legacyBytes - 4));
    });
  });

  group('Key wrapping (PIN)', () {
    late Key aesKey;

    setUp(() => aesKey = service.generateKey());

    test('wrapKey + unwrapKey with correct PIN returns original key', () {
      const pin = '1234';
      final wrapped = service.wrapKey(aesKey, pin);
      final unwrapped = service.unwrapKey(wrapped, pin);
      expect(unwrapped.bytes, equals(aesKey.bytes));
    });

    test('unwrapKey with wrong PIN throws', () {
      final wrapped = service.wrapKey(aesKey, '1234');
      expect(() => service.unwrapKey(wrapped, '9999'), throwsA(anything));
    });

    test('same PIN + different salt → different wrappedKey', () {
      const pin = '5678';
      final w1 = service.wrapKey(aesKey, pin);
      final w2 = service.wrapKey(aesKey, pin);
      // Salt is random each time
      expect(w1.saltB64, isNot(equals(w2.saltB64)));
    });

    test('wrappedKeyB64 is non-empty base64', () {
      final wrapped = service.wrapKey(aesKey, '0000');
      expect(wrapped.wrappedKeyB64, isNotEmpty);
      expect(wrapped.saltB64, isNotEmpty);
    });
  });
}
