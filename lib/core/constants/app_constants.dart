/// Cross-cutting values that are not text, theme or sizing.
///
/// Screen copy does not belong here — it lives on the screen that renders it.
abstract final class AppConstants {
  const AppConstants._();

  static const String appName = 'Capstone PropertyIntel';

  /// How long the splash screen holds before the app routes on.
  ///
  /// A branding beat with nothing behind it today. When auth lands it becomes
  /// the floor on a real wait rather than the whole wait.
  static const Duration splashDuration = Duration(milliseconds: 1200);

  // Networking. The API runs on a cold-starting host, so the first request
  // after an idle period can legitimately take far longer than a warm one.
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);
  static const Duration sendTimeout = Duration(seconds: 60);

  /// Page size for paginated list endpoints.
  static const int defaultPageSize = 20;

  /// How close to the bottom of a list we start loading the next page.
  static const double infiniteScrollThreshold = 400;

  /// Debounce applied to search fields before a query is issued.
  static const Duration searchDebounce = Duration(milliseconds: 350);

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

  /// Letters, spaces, hyphens and apostrophes only.
  static final RegExp namePattern = RegExp(r"^[a-zA-Z][a-zA-Z\s'-]*$");
}
