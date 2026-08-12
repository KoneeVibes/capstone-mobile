import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import 'failure_type.dart';

/// The single error object that travels from the data layer to the UI.
///
/// Nothing in the app may render a raw exception. Datasources throw, repository
/// implementations convert via `ErrorHandler.from`, and every provider surfaces
/// an [AppFailure]. Widgets read [message] and nothing else.
///
/// Construct these through `ErrorHandler` rather than by hand so the copy stays
/// consistent across every screen.
class AppFailure extends Equatable implements Exception {
  const AppFailure({
    required this.type,
    required this.message,
    this.statusCode,
    this.debugMessage,
  });

  /// What kind of failure this is. Drives retry and re-auth affordances.
  final FailureType type;

  /// User-facing copy. Always safe to render — never contains exception text,
  /// stack traces or server internals.
  final String message;

  /// HTTP status code when the failure came from a response, otherwise null.
  final int? statusCode;

  /// Diagnostic detail, populated only in debug builds and always null in
  /// release. Never render this: it is for logs and breakpoints only.
  final String? debugMessage;

  bool get isRetryable => type.isRetryable;

  bool get requiresReauthentication => type.requiresReauthentication;

  AppFailure copyWith({String? message}) => AppFailure(
    type: type,
    message: message ?? this.message,
    statusCode: statusCode,
    debugMessage: debugMessage,
  );

  /// [debugMessage] is deliberately excluded: two failures that read the same
  /// to the user are the same failure, so the UI does not rebuild just because
  /// the underlying exception text differed.
  @override
  List<Object?> get props => [type, message, statusCode];

  @override
  String toString() {
    if (kDebugMode) {
      return 'AppFailure(${type.name}, status: $statusCode, '
          'message: $message, debug: $debugMessage)';
    }
    return 'AppFailure(${type.name})';
  }
}
