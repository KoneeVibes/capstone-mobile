import '../constants/app_constants.dart';
import '../formatting/app_formatters.dart';

/// Form field validators, shaped for `TextFormField.validator`: they return an
/// error string when invalid and null when valid.
///
/// The field label is passed in by the caller so the message reads naturally on
/// whichever screen uses it, keeping screen wording on the screen.
abstract final class Validators {
  const Validators._();

  static String? requiredField(String? value, {required String label}) {
    if (value == null || value.trim().isEmpty) return '$label is required.';
    return null;
  }

  static String? email(String? value, {String label = 'Email'}) {
    final missing = requiredField(value, label: label);
    if (missing != null) return missing;

    if (!AppConstants.emailPattern.hasMatch(value!.trim())) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  /// Validates after [AppFormatters.trackingId], so `urf8t7c2` passes.
  static String? trackingId(String? value, {String label = 'Tracking ID'}) {
    final missing = requiredField(value, label: label);
    if (missing != null) return missing;

    if (!AppConstants.trackingIdPattern.hasMatch(
      AppFormatters.trackingId(value),
    )) {
      return 'Enter the full tracking ID, e.g. PI-URF8T7C2.';
    }
    return null;
  }

  static String? phone(String? value, {String label = 'Phone number'}) {
    final missing = requiredField(value, label: label);
    if (missing != null) return missing;

    // Strip spaces and dashes so display formatting does not fail validation.
    final normalised = value!.replaceAll(RegExp(r'[\s-]'), '');
    if (!AppConstants.phonePattern.hasMatch(normalised)) {
      return 'Enter a valid Nigerian phone number.';
    }
    return null;
  }

  static String? name(String? value, {required String label}) {
    final missing = requiredField(value, label: label);
    if (missing != null) return missing;

    final trimmed = value!.trim();
    if (trimmed.length < 2) return '$label must be at least 2 characters.';
    if (!AppConstants.namePattern.hasMatch(trimmed)) {
      return '$label can only contain letters, spaces, hyphens and apostrophes.';
    }
    return null;
  }

  /// Validates only when a value is present. For fields like middle name that
  /// are optional but still have to be well formed when filled in.
  static String? optionalName(String? value, {required String label}) {
    if (value == null || value.trim().isEmpty) return null;
    return name(value, label: label);
  }

  static String? minLength(
    String? value, {
    required String label,
    required int length,
  }) {
    final missing = requiredField(value, label: label);
    if (missing != null) return missing;

    if (value!.trim().length < length) {
      return '$label must be at least $length characters.';
    }
    return null;
  }

  /// Like [phone], but passes an empty field.
  static String? optionalPhone(String? value, {String label = 'Phone number'}) {
    if (value == null || value.trim().isEmpty) return null;
    return phone(value, label: label);
  }

  /// Untrimmed: a password's spaces are part of it.
  static String? password(String? value, {String label = 'Password'}) {
    if (value == null || value.isEmpty) return '$label is required.';
    if (value.length < AppConstants.minPasswordLength) {
      return '$label must be at least ${AppConstants.minPasswordLength} '
          'characters.';
    }
    return null;
  }

  /// The confirmation field: must repeat [original] exactly.
  static String? confirmation(String? value, {required String original}) {
    if (value == null || value.isEmpty) return 'Please repeat your password.';
    if (value != original) return "Passwords don't match.";
    return null;
  }
}
