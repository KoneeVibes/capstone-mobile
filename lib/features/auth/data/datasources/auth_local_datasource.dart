import '../../../../core/session/staff_role.dart';
import '../../../../core/storage/preferences_store.dart';
import '../../../../core/storage/secure_store.dart';

/// The token and staff role (secure storage) and the onboarding flag
/// (preferences). Throws on a platform failure.
class AuthLocalDataSource {
  const AuthLocalDataSource(this._secure, this._preferences);

  final SecureStore _secure;
  final PreferencesStore _preferences;

  static const String _tokenKey = 'auth_token';
  static const String _staffRoleKey = 'staff_role';
  static const String _onboardingSeenKey = 'onboarding_seen';

  Future<String?> readToken() => _secure.read(_tokenKey);

  /// Null when none is stored, which is every client session.
  Future<StaffRole?> readStaffRole() async {
    final value = await _secure.read(_staffRoleKey);
    return value == null ? null : StaffRole.fromApi(value);
  }

  Future<void> saveSession({required String token, StaffRole? staffRole}) async {
    await _secure.write(_tokenKey, token);
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
  }

  Future<bool> hasSeenOnboarding() async =>
      await _preferences.readBool(_onboardingSeenKey) ?? false;

  Future<void> markOnboardingSeen() =>
      _preferences.writeBool(_onboardingSeenKey, value: true);
}
