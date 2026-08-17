import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/staff/presentation/screens/staff_list_screen.dart';
import '../../shared/screens/placeholder_screen.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_state_view.dart';
import '../utils/error/app_failures.dart';
import 'app_routes.dart';
import 'app_session.dart';

/// The app's router.
///
/// Routes are split into a client branch and a staff branch; [_redirect] picks
/// the branch from the current role.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.rootPath,
    debugLogDiagnostics: kDebugMode,
    redirect: (context, state) => _redirect(ref, state),
    errorBuilder: (context, state) => const _RouteNotFoundScreen(),
    routes: [
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
        builder: (context, state) => PlaceholderScreen(
          title: 'Property Intel',
          message: 'Staff tools will appear here.',
          action: AppButton(
            label: 'Staff',
            icon: Icons.people_outline,
            expanded: false,
            onPressed: () => context.goNamed(AppRoutes.staffMembersName),
          ),
        ),
        routes: [
          GoRoute(
            path: 'members',
            name: AppRoutes.staffMembersName,
            builder: (context, state) => const StaffListScreen(),
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
    return role.isStaff ? AppRoutes.staffHomePath : AppRoutes.clientHomePath;
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
