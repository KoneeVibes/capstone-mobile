import 'app_failure.dart';
import 'failure_type.dart';

/// Failures the app declares rather than catches.
///
/// Most failures come from `ErrorHandler.from`, which maps a thrown object.
/// A few conditions are not exceptions at all — navigating to a route that does
/// not exist, for instance — but still have to reach the UI as an [AppFailure]
/// so every error is rendered the same way.
abstract final class AppFailures {
  const AppFailures._();

  static const AppFailure routeNotFound = AppFailure(
    type: FailureType.notFound,
    message: "That screen doesn't exist or has moved.",
  );

  static const AppFailure sessionExpired = AppFailure(
    type: FailureType.unauthorized,
    message: 'Your session has expired. Please sign in again.',
  );
}
