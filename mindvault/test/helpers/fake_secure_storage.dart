import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// In-memory fake for FlutterSecureStorage — avoids platform channel issues in tests.
class FakeSecureStorage implements FlutterSecureStorage {
  final _store = <String, String>{};

  @override
  Future<void> write({required String key, required String? value, IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, MacOsOptions? mOptions, WindowsOptions? wOptions}) async {
    if (value == null) { _store.remove(key); } else { _store[key] = value; }
  }

  @override
  Future<String?> read({required String key, IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, MacOsOptions? mOptions, WindowsOptions? wOptions}) async => _store[key];

  @override
  Future<void> delete({required String key, IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, MacOsOptions? mOptions, WindowsOptions? wOptions}) async => _store.remove(key);

  @override
  Future<bool> containsKey({required String key, IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, MacOsOptions? mOptions, WindowsOptions? wOptions}) async => _store.containsKey(key);

  @override
  Future<Map<String, String>> readAll({IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, MacOsOptions? mOptions, WindowsOptions? wOptions}) async => Map.unmodifiable(_store);

  @override
  Future<void> deleteAll({IOSOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, MacOsOptions? mOptions, WindowsOptions? wOptions}) async => _store.clear();

  @override AndroidOptions get aOptions => const AndroidOptions();
  @override IOSOptions get iOptions => const IOSOptions();
  @override LinuxOptions get lOptions => const LinuxOptions();
  @override MacOsOptions get mOptions => const MacOsOptions();
  @override WebOptions get webOptions => const WebOptions();
  @override WindowsOptions get wOptions => const WindowsOptions();

  // iOS-only members — not used on Android/Windows. noSuchMethod satisfies the interface.
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
