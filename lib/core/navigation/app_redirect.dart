import 'app_routes.dart';
import 'app_session.dart';

/// Where a user with [role] at [location] should be sent, or null to stay.
///
/// Pure, so the rules are unit-tested without a router. Each role is kept to
/// its own branch: the root and the other role's routes both land on the
/// role's home tab.
///
/// TODO(auth): signed-out users still stay where they are; send them to sign
/// in once authentication exists.
String? redirectFor({required AppRole? role, required String location}) {
  if (role == null) return null;

  final home = homePathFor(role);
  if (location == AppRoutes.rootPath) return home;

  final foreignBranch = role.isStaff
      ? AppRoutes.clientRootPath
      : AppRoutes.staffHomePath;
  if (_isWithin(location, foreignBranch)) return home;

  return null;
}

/// The tab a role lands on.
String homePathFor(AppRole role) =>
    role.isStaff ? AppRoutes.dashboardPath : AppRoutes.clientHomePath;

/// True for [prefix] itself and anything below it — but not `/staffing`.
bool _isWithin(String location, String prefix) =>
    location == prefix || location.startsWith('$prefix/');
