import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_failure.dart';
import 'error_handler.dart';

/// Safety net for the "no raw error reaches the UI" rule.
///
/// Providers are expected to surface an [AppFailure], but an unplanned throw
/// inside a provider body would otherwise land in [AsyncValue.error] as a raw
/// exception. Reading errors through [failure] normalises anything that got
/// through, so a widget cannot render exception text even by accident.
///
/// Widgets should use this instead of touching [AsyncValue.error] directly.
extension AsyncValueFailureX<T> on AsyncValue<T> {
  /// The failure behind an errored state, or null when not errored.
  AppFailure? get failure {
    final raw = error;
    if (!hasError || raw == null) return null;
    return ErrorHandler.from(raw, stackTrace);
  }

  /// Folds the three states into a single value, handing the error branch a
  /// ready-made [AppFailure].
  R when2<R>({
    required R Function(T value) data,
    required R Function() loading,
    required R Function(AppFailure failure) error,
  }) {
    if (hasError) return error(failure!);
    if (isLoading && !hasValue) return loading();
    return data(requireValue);
  }
}
