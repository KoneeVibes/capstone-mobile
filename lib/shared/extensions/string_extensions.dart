/// Small string helpers used across screens and models.
extension StringX on String {
  bool get isBlank => trim().isEmpty;

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

extension NullableStringX on String? {
  bool get isNullOrBlank => this == null || this!.trim().isEmpty;

  bool get isNotNullOrBlank => !isNullOrBlank;

  /// The value when present, otherwise [fallback].
  String orElse(String fallback) => isNullOrBlank ? fallback : this!.trim();
}
