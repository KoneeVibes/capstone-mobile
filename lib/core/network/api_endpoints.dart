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

  // Property search: the priced locations a case can be filed for.
  static const String locations = '/misc/location';

  // Search across cases and users, narrowed with `flag` (`case`, `staff`).
  static const String search = '/search';

  // Payment: the invoice a new case creates, and the Paystack transaction that
  // settles it.

  /// Accepts the invoice's own id or its case id; both resolve the invoice.
  static String invoiceById(String lookupId) => '/invoice/$lookupId';

  /// Takes the invoice's own id only.
  static String settleInvoice(String invoiceId) => '/invoice/settle/$invoiceId';

  /// Paystack's hosted checkout for an initialised transaction. Not our API.
  static String paystackCheckout(String accessCode) =>
      'https://checkout.paystack.com/${Uri.encodeComponent(accessCode)}';
}
