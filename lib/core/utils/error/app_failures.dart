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

  /// The picker plugin failed, most often because library access was denied.
  ///
  /// A `PlatformException` would otherwise flatten to a generic "Something went
  /// wrong", which tells the user nothing they can act on.
  static const AppFailure mediaPickFailed = AppFailure(
    type: FailureType.unknown,
    message:
        "We couldn't open your photos. Check that Property Intel has "
        'permission, then try again.',
  );

  static const AppFailure unsupportedFileType = AppFailure(
    type: FailureType.validation,
    message: "That file type isn't supported. Choose a JPG or PNG image.",
  );

  static const AppFailure unsupportedDocumentType = AppFailure(
    type: FailureType.validation,
    message: "That file type isn't supported. Choose a PDF, Word or image file.",
  );

  static const AppFailure fileTooLarge = AppFailure(
    type: FailureType.validation,
    message: 'That file is too large. Choose one under 10 MB.',
  );

  /// A document link could not be handed to the browser or a viewer.
  ///
  /// Covers a malformed URL and a device with nothing registered for it.
  /// The two read the same to the user and there is nothing different to do
  /// about either, so they share one message.
  static const AppFailure linkNotOpenable = AppFailure(
    type: FailureType.unknown,
    message:
        "We couldn't open that document. Try again, or open it on the "
        'web app.',
  );

  /// The picker returned an entry with no readable path on disk.
  static const AppFailure fileUnreadable = AppFailure(
    type: FailureType.unknown,
    message: "We couldn't read that file. Try choosing it again.",
  );
}
