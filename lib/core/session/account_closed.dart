import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What to do once the signed-in user's account has been deleted. A no-op by
/// default; `authOverrides` ends the session, so Profile never imports auth.
final accountClosedHandlerProvider = Provider<Future<void> Function()>((ref) {
  return () async {};
});
