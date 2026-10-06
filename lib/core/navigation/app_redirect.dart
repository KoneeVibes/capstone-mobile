import 'app_routes.dart';
import 'app_session.dart';

/// Where a user at [location] should be sent, or null to stay.
///
/// Pure, so the rules are unit-tested without a router:
/// - the splash and the legal pages are open to everyone;
/// - signed out, everything else lands on onboarding until it has been seen,
///   then on login — the other sign-in screens stay reachable;
/// - signed in, the sign-in screens and the other role's shell land on the
///   role's home tab, as does the Staff tab without [canViewStaff].
String? redirectFor({
  required AppRole? role,
  required bool hasSeenOnboarding,
  required String location,
  bool canViewStaff = false,
}) {
  if (location == AppRoutes.splashPath || _isLegal(location)) return null;

  if (role == null) {
    if (!hasSeenOnboarding) {
      return location == AppRoutes.onboardingPath
          ? null
          : AppRoutes.onboardingPath;
    }
    if (location == AppRoutes.onboardingPath) return AppRoutes.loginPath;
    return _isSignedOutRoute(location) ? null : AppRoutes.loginPath;
  }

  final home = homePathFor(role);
  if (location == AppRoutes.rootPath || _isSignedOutRoute(location)) {
    return home;
  }

  final foreignBranch = role.isStaff
      ? AppRoutes.clientRootPath
      : AppRoutes.staffHomePath;
  if (_isWithin(location, foreignBranch)) return home;

  if (!canViewStaff && _isWithin(location, AppRoutes.staffMembersPath)) {
    return home;
  }

  return null;
}

/// The tab a role lands on.
String homePathFor(AppRole role) =>
    role.isStaff ? AppRoutes.dashboardPath : AppRoutes.clientHomePath;

bool _isSignedOutRoute(String location) =>
    location == AppRoutes.onboardingPath ||
    _isWithin(location, AppRoutes.loginPath) ||
    _isWithin(location, AppRoutes.registerPath) ||
    _isWithin(location, AppRoutes.forgotPasswordPath);

bool _isLegal(String location) =>
    location == AppRoutes.privacyPolicyPath || location == AppRoutes.termsPath;

/// True for [prefix] itself and anything below it — but not `/staffing`.
bool _isWithin(String location, String prefix) =>
    location == prefix || location.startsWith('$prefix/');
