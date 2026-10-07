/// Every URL the app talks to.
///
/// The host is compile-time configurable so builds can be pointed at another
/// environment without a code change:
///
/// ```
/// flutter run --dart-define=API_BASE_URL=https://staging.example.com
/// ```
abstract final class ApiEndpoints {
  const ApiEndpoints._();

  static const String host = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://capstone-be-1hri.onrender.com',
  );

  static const String _version = '/api/v1';

  /// Dio's `baseUrl`. Paths below are relative to it.
  static const String baseUrl = '$host$_version';

  // Auth.
  static const String signIn = '/auth/signin';
  static const String signUp = '/auth/signup';
  static const String verifyOtp = '/auth/verify-otp';
  static const String forgotPassword = '/auth/forgot-password';
  static const String signOut = '/auth/signout';

  // Staff.
  static const String staff = '/staff';

  static String staffById(String userId) => '$staff/$userId';

  // Cases. Singular path: the API exposes /case, not /cases.
  static const String cases = '/case';

  static String caseById(String caseId) => '$cases/$caseId';

  static String trackCase(String trackingId) =>
      '$cases/track/${Uri.encodeComponent(trackingId)}';

  // Property search: the priced locations a case can be filed for, and the
  // invoice a new case creates.
  static const String locations = '/misc/location';

  static String invoiceById(String invoiceId) => '/invoice/$invoiceId';
}
