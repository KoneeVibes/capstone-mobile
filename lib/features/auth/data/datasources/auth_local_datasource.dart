import '../../../../core/storage/preferences_store.dart';
import '../../../../core/storage/secure_store.dart';

/// The token (secure storage) and the onboarding flag (preferences).
/// Throws on a platform failure.
class AuthLocalDataSource {
  const AuthLocalDataSource(this._secure, this._preferences);

  final SecureStore _secure;
  final PreferencesStore _preferences;

  static const String _tokenKey = 'auth_token';
  static const String _onboardingSeenKey = 'onboarding_seen';

  Future<String?> readToken() => _secure.read(_tokenKey);

  Future<void> saveToken(String token) => _secure.write(_tokenKey, token);

  Future<void> deleteToken() => _secure.delete(_tokenKey);

  Future<bool> hasSeenOnboarding() async =>
      await _preferences.readBool(_onboardingSeenKey) ?? false;

  Future<void> markOnboardingSeen() =>
      _preferences.writeBool(_onboardingSeenKey, value: true);
}
