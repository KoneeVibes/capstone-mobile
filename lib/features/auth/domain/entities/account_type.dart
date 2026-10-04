import '../../../../core/navigation/app_session.dart';

/// The token's `type` claim. The backend's three values, confirmed 4 Oct 2026.
enum AccountType {
  staff('staff'),
  registeredClient('registered-client'),
  guestClient('guest-client');

  const AccountType(this.apiValue);

  final String apiValue;

  /// Both client types share the client shell.
  AppRole get role => this == staff ? AppRole.staff : AppRole.client;

  /// Null for a value this build does not know — the caller refuses the
  /// sign-in rather than guessing a shell.
  static AccountType? fromApi(Object? value) {
    for (final type in values) {
      if (type.apiValue == value) return type;
    }
    return null;
  }
}
