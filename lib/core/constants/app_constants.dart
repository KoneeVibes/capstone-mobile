/// Cross-cutting values that are not text, theme or sizing.
///
/// Screen copy does not belong here — it lives on the screen that renders it.
abstract final class AppConstants {
  const AppConstants._();

  static const String appName = 'Property Intel';

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

  // Validation patterns.
  static final RegExp emailPattern = RegExp(
    r'^[\w.!#$%&’*+/=?^`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$',
  );

  /// Nigerian mobile numbers, accepting local (`08034112290`), international
  /// (`+2348034112290`) and spaced (`0701 882 4471`) forms.
  static final RegExp phonePattern = RegExp(r'^(?:\+?234|0)[789]\d{9}$');

  /// Letters, spaces, hyphens and apostrophes only.
  static final RegExp namePattern = RegExp(r"^[a-zA-Z][a-zA-Z\s'-]*$");
}
