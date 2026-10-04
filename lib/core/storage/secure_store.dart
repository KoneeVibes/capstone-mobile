import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Encrypted key-value storage for secrets (the session token).
///
/// An interface so features and tests never touch the platform channel behind
/// it. Methods throw on a platform failure; callers decide whether that matters.
abstract class SecureStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

/// Keychain on iOS, Keystore-backed storage on Android.
class FlutterSecureStore implements SecureStore {
  const FlutterSecureStore([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

final secureStoreProvider = Provider<SecureStore>(
  (ref) => const FlutterSecureStore(),
);
