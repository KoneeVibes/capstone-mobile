import '../../../../core/session/staff_role.dart';
import '../../../../core/storage/preferences_store.dart';
import '../../../../core/storage/secure_store.dart';

/// The token, staff role and sign-in email (secure storage) and the onboarding
/// flag (preferences). Throws on a platform failure.
class AuthLocalDataSource {
  const AuthLocalDataSource(this._secure, this._preferences);

  final SecureStore _secure;
  final PreferencesStore _preferences;

  static const String _tokenKey = 'auth_token';
  static const String _staffRoleKey = 'staff_role';
  static const String _emailKey = 'auth_email';
  static const String _onboardingSeenKey = 'onboarding_seen';

  Future<String?> readToken() => _secure.read(_tokenKey);

  /// Null for a session saved before the email was kept.
  Future<String?> readEmail() => _secure.read(_emailKey);

  /// Null when none is stored, which is every client session.
  Future<StaffRole?> readStaffRole() async {
    final value = await _secure.read(_staffRoleKey);
    return value == null ? null : StaffRole.fromApi(value);
  }

  Future<void> saveSession({
    required String token,
    StaffRole? staffRole,
    String? email,
  }) async {
    await _secure.write(_tokenKey, token);
    if (email == null) {
      await _secure.delete(_emailKey);
    } else {
      await _secure.write(_emailKey, email);
    }
    if (staffRole == null) {
      await _secure.delete(_staffRoleKey);
    } else {
      await saveStaffRole(staffRole);
    }
  }

  Future<void> saveStaffRole(StaffRole role) =>
      _secure.write(_staffRoleKey, role.apiValue);

  Future<void> deleteSession() async {
    await _secure.delete(_tokenKey);
    await _secure.delete(_staffRoleKey);
    await _secure.delete(_emailKey);
  }

  Future<bool> hasSeenOnboarding() async =>
      await _preferences.readBool(_onboardingSeenKey) ?? false;

  Future<void> markOnboardingSeen() =>
      _preferences.writeBool(_onboardingSeenKey, value: true);
}
