/// Cross-cutting values that are not text, theme or sizing.
///
/// Screen copy does not belong here — it lives on the screen that renders it.
abstract final class AppConstants {
  const AppConstants._();

  static const String appName = 'Capstone PropertyIntel';

  /// The least time the splash holds, even when the session restores faster.
  static const Duration splashDuration = Duration(milliseconds: 1200);

  // Networking. The API runs on a cold-starting host, so the first request
  // after an idle period can legitimately take far longer than a warm one.
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);
  static const Duration sendTimeout = Duration(seconds: 60);

  /// Page size for paginated list endpoints.
  static const int defaultPageSize = 20;

  /// Page size when a list endpoint is walked whole. High enough that one
  /// request almost always covers the set.
  static const int listWalkPageSize = 100;

  /// How close to the bottom of a list we start loading the next page.
  static const double infiniteScrollThreshold = 400;

  /// Debounce applied to search fields before a query is issued.
  static const Duration searchDebounce = Duration(milliseconds: 350);

  // Auth.

  /// Digits in a sign-up or password-reset code.
  static const int otpLength = 6;

  /// How long the backend refuses a new code for the same email.
  static const Duration otpResendCooldown = Duration(minutes: 10);

  static const int minPasswordLength = 8;

  /// Sent as `organization` on every client sign-up.
  static const String signUpOrganization = 'PropertyIntel Partners';

  /// Longest response body written to the debug log, in characters.
  static const int maxLoggedBodyLength = 2000;

  // Uploads.

  /// Largest file the app will attempt to upload, in bytes (10 MB).
  ///
  /// Rejecting locally gives the user an immediate, specific message instead of
  /// a slow round trip ending in a 413.
  static const int maxUploadBytes = 10 * 1024 * 1024;

  /// Image formats the staff API accepts.
  static const Set<String> allowedImageExtensions = {'jpg', 'jpeg', 'png'};

  /// Formats accepted where a document is expected.
  static const Set<String> allowedDocumentExtensions = {'pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'};

  /// Longest edge of a picked image, in pixels. Re-encoding at this size keeps
  /// uploads small and normalises HEIC to JPEG.
  static const double maxImageDimension = 1024;

  /// JPEG quality applied to picked images, 0-100.
  static const int pickedImageQuality = 85;

  // Validation patterns.
  static final RegExp emailPattern = RegExp(r'^[\w.!#$%&’*+/=?^`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$');

  /// Nigerian mobile numbers, accepting local (`08034112290`), international
  /// (`+2348034112290`) and spaced (`0701 882 4471`) forms.
  static final RegExp phonePattern = RegExp(r'^(?:\+?234|0)[789]\d{9}$');

  /// A case tracking ID, e.g. `PI-URF8T7C2`. Matches every ID on the live API.
  static final RegExp trackingIdPattern = RegExp(r'^PI-[A-Z0-9]{8}$');

  /// Letters, spaces, hyphens and apostrophes only.
  static final RegExp namePattern = RegExp(r"^[a-zA-Z][a-zA-Z\s'-]*$");
}
