/// Classification of every error the app can surface.
///
/// The type drives UI decisions (retry affordance, sign-out prompt, and so on).
/// The user-facing copy lives on [AppFailure.message], produced by
/// `ErrorHandler`, so nothing else in the app decides how an error reads.
enum FailureType {
  /// Device is offline, DNS failed, or the host is unreachable.
  network,

  /// Connect, send or receive exceeded the configured timeout.
  timeout,

  /// HTTP 400 and other malformed-request responses.
  badRequest,

  /// HTTP 401 — credentials missing, invalid or expired.
  unauthorized,

  /// HTTP 403 — authenticated but not permitted.
  forbidden,

  /// HTTP 404 — the resource does not exist.
  notFound,

  /// HTTP 409 — the resource already exists or conflicts with current state.
  conflict,

  /// HTTP 422 — semantically invalid payload.
  validation,

  /// HTTP 429 — throttled.
  rateLimited,

  /// HTTP 5xx — the fault is on the server side.
  server,

  /// The request was cancelled, usually because the screen was disposed.
  cancelled,

  /// The response did not match the shape the app expected.
  parsing,

  /// Anything undocumented and unclassifiable.
  unknown;

  /// Whether offering the user a "Try again" action makes sense.
  ///
  /// Retrying an unauthorised or forbidden request just fails again, and a
  /// cancelled request was deliberate.
  bool get isRetryable => switch (this) {
    FailureType.network ||
    FailureType.timeout ||
    FailureType.server ||
    FailureType.rateLimited ||
    FailureType.unknown => true,
    FailureType.badRequest ||
    FailureType.unauthorized ||
    FailureType.forbidden ||
    FailureType.notFound ||
    FailureType.conflict ||
    FailureType.validation ||
    FailureType.cancelled ||
    FailureType.parsing => false,
  };

  /// Whether this failure means the session is no longer usable.
  bool get requiresReauthentication => this == FailureType.unauthorized;
}
