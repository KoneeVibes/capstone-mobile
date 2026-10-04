import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Plain key-value storage for flags that are not secret.
///
/// Unlike `SecureStore` it is wiped when the app is uninstalled on both
/// platforms, which is what makes it a reliable "first launch" marker.
abstract class PreferencesStore {
  Future<bool?> readBool(String key);

  Future<void> writeBool(String key, {required bool value});
}

class SharedPreferencesStore implements PreferencesStore {
  SharedPreferencesStore([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<bool?> readBool(String key) => _preferences.getBool(key);

  @override
  Future<void> writeBool(String key, {required bool value}) =>
      _preferences.setBool(key, value);
}

final preferencesStoreProvider = Provider<PreferencesStore>(
  (ref) => SharedPreferencesStore(),
);
