/// Small string helpers used across screens and models.
extension StringX on String {
  /// True when the string is empty or only whitespace.
  bool get isBlank => trim().isEmpty;

  /// True when the string holds something other than whitespace.
  bool get isNotBlank => trim().isNotEmpty;

  /// `manager` -> `Manager`. Leaves the rest of the string untouched.
  String get capitalised {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Returns null when the string holds nothing meaningful, so optional API
  /// fields are omitted rather than sent as empty strings.
  String? get nullIfBlank => isBlank ? null : trim();
}

/// The same helpers for values that may be null, such as optional API fields.
extension NullableStringX on String? {
  /// True when null, empty or only whitespace.
  bool get isNullOrBlank => this == null || this!.trim().isEmpty;

  /// True when present and not just whitespace.
  bool get isNotNullOrBlank => !isNullOrBlank;

  /// The value when present, otherwise [fallback].
  String orElse(String fallback) => isNullOrBlank ? fallback : this!.trim();
}
