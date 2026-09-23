import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/cases/presentation/screens/case_detail_screen.dart';
import '../../features/cases/presentation/screens/cases_list_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/tracking_progress_screen.dart';
import '../../features/staff/presentation/screens/staff_list_screen.dart';
import '../../shared/screens/placeholder_screen.dart';
import '../../shared/screens/splash_screen.dart';
import '../../shared/widgets/app_state_view.dart';
import '../utils/error/app_failures.dart';
import 'app_routes.dart';
import 'app_session.dart';
import 'app_shell.dart';

/// The app's router.
///
/// Routes are split into a client branch and a staff branch; [_redirect] picks
/// the branch from the current role.
///
/// The app opens on the splash route, which hands off to [AppRoutes.rootPath]
/// once it has held its beat; the redirect below takes it from there.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splashPath,
    debugLogDiagnostics: kDebugMode,
    redirect: (context, state) => _redirect(ref, state),
    errorBuilder: (context, state) => const _RouteNotFoundScreen(),
    routes: [
      GoRoute(
        path: AppRoutes.splashPath,
        name: AppRoutes.splashName,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.rootPath,
        name: AppRoutes.rootName,
        builder: (context, state) => const PlaceholderScreen(
          title: 'Property Intel',
          message: 'Sign in to continue.',
          showAppBar: false,
        ),
      ),
      GoRoute(
        path: AppRoutes.clientHomePath,
        name: AppRoutes.clientHomeName,
        builder: (context, state) => const PlaceholderScreen(
          title: 'Dashboard',
          message: 'Your requests and reports will appear here.',
        ),
      ),
      GoRoute(
        path: AppRoutes.staffHomePath,
        name: AppRoutes.staffHomeName,
        redirect: (context, state) => AppRoutes.dashboardPath,
      ),
      // Branch order must match AppShell's items.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dashboardPath,
                name: AppRoutes.dashboardName,
                builder: (context, state) => const DashboardScreen(),
                routes: [
                  GoRoute(
                    path: 'track/:trackingId',
                    name: AppRoutes.trackingProgressName,
                    builder: (context, state) => TrackingProgressScreen(
                      trackingId: state.pathParameters['trackingId'] ?? '',
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.casesPath,
                name: AppRoutes.casesName,
                builder: (context, state) => const CasesListScreen(),
                routes: [
                  GoRoute(
                    path: ':caseId',
                    name: AppRoutes.caseDetailName,
                    // Missing rather than bang: an empty id reaches the
                    // repository and comes back as a normal "not found"
                    // failure screen, which is what a mistyped deep link
                    // should produce.
                    builder: (context, state) => CaseDetailScreen(
                      caseId: state.pathParameters['caseId'] ?? '',
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.staffMembersPath,
                name: AppRoutes.staffMembersName,
                builder: (context, state) => const StaffListScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// Sends the user to the branch that matches their role.
///
/// TODO(auth): once authentication exists, also bounce unauthenticated users
/// away from protected routes and pass a `refreshListenable` to [GoRouter] so a
/// sign-in or sign-out re-evaluates this immediately.
String? _redirect(Ref ref, GoRouterState state) {
  final role = ref.read(sessionProvider);

  // Signed out: stay where we are. Returning the current location would loop.
  if (role == null) return null;

  if (state.matchedLocation == AppRoutes.rootPath) {
    return role.isStaff ? AppRoutes.dashboardPath : AppRoutes.clientHomePath;
  }

  return null;
}

class _RouteNotFoundScreen extends StatelessWidget {
  const _RouteNotFoundScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: AppStateView.failure(
        title: 'Page not found',
        failure: AppFailures.routeNotFound,
        onRetry: () => context.goNamed(AppRoutes.rootName),
        retryLabel: 'Go home',
      ),
    );
  }
}
