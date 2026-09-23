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

  // Staff.
  static const String staff = '/staff';

  static String staffById(String userId) => '$staff/$userId';

  // Cases. Singular path: the API exposes /case, not /cases.
  static const String cases = '/case';

  static String caseById(String caseId) => '$cases/$caseId';

  static String trackCase(String trackingId) =>
      '$cases/track/${Uri.encodeComponent(trackingId)}';
}
