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
import 'app_redirect.dart';
import 'app_routes.dart';
import 'app_session.dart';
import 'app_shell.dart';

/// The app's router.
///
/// Routes are split into a client shell and a staff shell; [redirectFor] keeps
/// each role inside its own.
///
/// The app opens on the splash route, which hands off to [AppRoutes.rootPath]
/// once it has held its beat; the redirect takes it from there.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splashPath,
    debugLogDiagnostics: kDebugMode,
    // TODO(auth): pass a `refreshListenable` so a sign-in or sign-out
    // re-evaluates this immediately.
    redirect: (context, state) => redirectFor(
      role: ref.read(sessionProvider),
      location: state.matchedLocation,
    ),
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
        path: AppRoutes.clientRootPath,
        name: AppRoutes.clientRootName,
        redirect: (context, state) => AppRoutes.clientHomePath,
      ),
      GoRoute(
        path: AppRoutes.staffHomePath,
        name: AppRoutes.staffHomeName,
        redirect: (context, state) => AppRoutes.dashboardPath,
      ),
      // Branch order must match AppShell.clientTabs.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(
          navigationShell: navigationShell,
          tabs: AppShell.clientTabs,
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.clientHomePath,
                name: AppRoutes.clientHomeName,
                builder: (context, state) => const PlaceholderScreen(
                  title: 'Home',
                  message: 'Your cases and recent searches will appear here.',
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.clientSearchPath,
                name: AppRoutes.clientSearchName,
                builder: (context, state) => const PlaceholderScreen(
                  title: 'Search',
                  message:
                      'Look up a tracking ID or start a new property search.',
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.clientCasesPath,
                name: AppRoutes.clientCasesName,
                builder: (context, state) => const CasesListScreen(
                  detailRouteName: AppRoutes.clientCaseDetailName,
                ),
                routes: [
                  GoRoute(
                    path: ':caseId',
                    name: AppRoutes.clientCaseDetailName,
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
                path: AppRoutes.clientProfilePath,
                name: AppRoutes.clientProfileName,
                builder: (context, state) => const _ProfilePlaceholder(),
              ),
            ],
          ),
        ],
      ),
      // Branch order must match AppShell.staffTabs.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(
          navigationShell: navigationShell,
          tabs: AppShell.staffTabs,
        ),
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
                builder: (context, state) => const CasesListScreen(
                  detailRouteName: AppRoutes.caseDetailName,
                ),
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
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.staffProfilePath,
                name: AppRoutes.staffProfileName,
                builder: (context, state) => const _ProfilePlaceholder(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// Both roles' Profile tab until the profile screen is designed.
class _ProfilePlaceholder extends StatelessWidget {
  const _ProfilePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Profile',
      message: 'Your account details will appear here.',
    );
  }
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
