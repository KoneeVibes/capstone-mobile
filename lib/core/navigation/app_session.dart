import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which side of the product the signed-in user sees.
///
/// One app serves both audiences; the role decides the route branch and the
/// navigation shell.
enum AppRole {
  client,
  staff;

  bool get isStaff => this == AppRole.staff;

  bool get isClient => this == AppRole.client;
}

/// The current role, or null when signed out.
///
/// TEMPORARY: authentication is not built yet, so this reports the role named
/// by `--dart-define=APP_ROLE=client|staff` (staff when unset), which makes
/// both shells reachable before sign-in exists.
///
/// TODO(auth): derive this from the session token. The router and the cases
/// feature already read it and need no change.
final sessionProvider = Provider<AppRole?>(
  (ref) => devRoleFrom(const String.fromEnvironment('APP_ROLE')),
);

/// Reads the `APP_ROLE` define. Anything but `client` keeps the staff default.
@visibleForTesting
AppRole devRoleFrom(String value) =>
    value.trim().toLowerCase() == 'client' ? AppRole.client : AppRole.staff;
