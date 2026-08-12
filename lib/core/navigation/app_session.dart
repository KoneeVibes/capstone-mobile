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
/// TEMPORARY: authentication is not built yet, so this reports [AppRole.staff]
/// unconditionally to make the staff branch reachable while the first feature
/// is developed and tested.
///
/// When auth lands, move this to `features/auth` and derive it from the session:
/// the router already reads it and needs no change.
final sessionProvider = Provider<AppRole?>((ref) => AppRole.staff);
