import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/password_changed_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/auth/presentation/screens/verify_code_screen.dart';
import '../../features/auth/presentation/widgets/sign_out_button.dart';
import '../../features/cases/presentation/screens/case_detail_screen.dart';
import '../../features/cases/presentation/screens/cases_list_screen.dart';
import '../../features/cases/presentation/screens/dispute_detail_screen.dart';
import '../../features/cases/presentation/screens/submit_dispute_screen.dart';
import '../../features/chat/presentation/screens/case_chat_screen.dart';
import '../../features/dashboard/presentation/screens/client_home_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/staff_home_screen.dart';
import '../../features/dashboard/presentation/screens/tracking_progress_screen.dart';
import '../../features/payment/presentation/screens/invoice_screen.dart';
import '../../features/property_search/presentation/screens/search_property_screen.dart';
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
/// Signed-out routes sit at the top level; signed-in ones are split into a
/// client shell and a staff shell. [redirectFor] keeps everyone where they
/// belong.
///
/// The app opens on the splash route, which hands off to [AppRoutes.rootPath]
/// once it has held its beat; the redirect takes it from there.
final appRouterProvider = Provider<GoRouter>((ref) {
  // Re-runs the redirect the moment someone signs in or out, or finishes
  // onboarding.
  final refresh = ValueNotifier<int>(0);
  ref
    ..listen(sessionProvider, (_, _) => refresh.value++)
    ..listen(hasSeenOnboardingProvider, (_, _) => refresh.value++)
    ..onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splashPath,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: refresh,
    redirect: (context, state) {
      final user = ref.read(sessionProvider);
      return redirectFor(
        role: user?.role,
        hasSeenOnboarding: ref.read(hasSeenOnboardingProvider),
        location: state.matchedLocation,
        canViewStaff: user?.permissions.canViewStaff ?? false,
      );
    },
    errorBuilder: (context, state) => const _RouteNotFoundScreen(),
    routes: [
      GoRoute(
        path: AppRoutes.splashPath,
        name: AppRoutes.splashName,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboardingPath,
        name: AppRoutes.onboardingName,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.loginPath,
        name: AppRoutes.loginName,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.registerPath,
        name: AppRoutes.registerName,
        builder: (context, state) => const RegisterScreen(),
        routes: [
          GoRoute(
            path: 'verify',
            name: AppRoutes.registerVerifyName,
            builder: (context, state) =>
                const VerifyCodeScreen(purpose: OtpPurpose.signUp),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.forgotPasswordPath,
        name: AppRoutes.forgotPasswordName,
        builder: (context, state) => const ForgotPasswordScreen(),
        routes: [
          GoRoute(
            path: 'verify',
            name: AppRoutes.forgotPasswordVerifyName,
            builder: (context, state) =>
                const VerifyCodeScreen(purpose: OtpPurpose.passwordReset),
          ),
          GoRoute(
            path: 'reset',
            name: AppRoutes.resetPasswordName,
            builder: (context, state) => const ResetPasswordScreen(),
          ),
          GoRoute(
            path: 'done',
            name: AppRoutes.passwordChangedName,
            builder: (context, state) => const PasswordChangedScreen(),
          ),
        ],
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
      // Top-level, so a case conversation opens full screen over the shell. The
      // staff-only redirect keeps clients out. Mock UI for now.
      GoRoute(
        path: AppRoutes.caseChatPath,
        name: AppRoutes.caseChatName,
        builder: (context, state) => CaseChatScreen(
          caseId: state.pathParameters['caseId'] ?? '',
          reference: state.uri.queryParameters['ref'],
        ),
      ),
      // The client's side of the same conversation; either side may open or
      // close it.
      GoRoute(
        path: AppRoutes.clientCaseChatPath,
        name: AppRoutes.clientCaseChatName,
        builder: (context, state) => CaseChatScreen(
          caseId: state.pathParameters['caseId'] ?? '',
          reference: state.uri.queryParameters['ref'],
        ),
      ),
      // Disputes open full screen, like the chat. `new` is listed before the
      // id route so it is never read as a dispute id.
      GoRoute(
        path: AppRoutes.clientRaiseDisputePath,
        name: AppRoutes.clientRaiseDisputeName,
        builder: (context, state) =>
            SubmitDisputeScreen(caseId: state.pathParameters['caseId'] ?? ''),
      ),
      GoRoute(
        path: AppRoutes.clientDisputePath,
        name: AppRoutes.clientDisputeName,
        builder: (context, state) => _dispute(state),
      ),
      GoRoute(
        path: AppRoutes.staffDisputePath,
        name: AppRoutes.staffDisputeName,
        builder: (context, state) => _dispute(state),
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
                builder: (context, state) => const ClientHomeScreen(
                  searchPropertyRouteName: AppRoutes.clientSearchPropertyName,
                  progressRouteName: AppRoutes.clientTrackingProgressName,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.clientSearchPath,
                name: AppRoutes.clientSearchName,
                builder: (context, state) => const DashboardScreen(
                  progressRouteName: AppRoutes.clientTrackingProgressName,
                  searchPropertyRouteName: AppRoutes.clientSearchPropertyName,
                ),
                routes: [
                  GoRoute(
                    path: 'track/:trackingId',
                    name: AppRoutes.clientTrackingProgressName,
                    builder: (context, state) => TrackingProgressScreen(
                      trackingId: state.pathParameters['trackingId'] ?? '',
                      fallbackRouteName: AppRoutes.clientSearchName,
                    ),
                  ),
                  GoRoute(
                    path: 'property',
                    name: AppRoutes.clientSearchPropertyName,
                    builder: (context, state) => const SearchPropertyScreen(
                      quoteRouteName: AppRoutes.clientSearchQuoteName,
                    ),
                  ),
                  GoRoute(
                    path: 'quote/:invoiceId',
                    name: AppRoutes.clientSearchQuoteName,
                    builder: (context, state) => _quote(
                      state,
                      trackRouteName: AppRoutes.clientTrackingProgressName,
                    ),
                  ),
                ],
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
                  chatRouteName: AppRoutes.clientCaseChatName,
                  payRouteName: AppRoutes.clientCasePayName,
                  trackRouteName: AppRoutes.clientCaseTrackName,
                ),
                routes: [
                  GoRoute(
                    path: ':caseId',
                    name: AppRoutes.clientCaseDetailName,
                    builder: (context, state) => CaseDetailScreen(
                      caseId: state.pathParameters['caseId'] ?? '',
                      chatRouteName: AppRoutes.clientCaseChatName,
                      disputeRouteName: AppRoutes.clientDisputeName,
                      payRouteName: AppRoutes.clientCasePayName,
                      trackRouteName: AppRoutes.clientCaseTrackName,
                      raiseDisputeRouteName: AppRoutes.clientRaiseDisputeName,
                    ),
                    routes: [
                      // Kept inside the Cases tab, rather than jumping to the
                      // Search tab's copy of the timeline.
                      GoRoute(
                        path: 'track/:trackingId',
                        name: AppRoutes.clientCaseTrackName,
                        builder: (context, state) => TrackingProgressScreen(
                          trackingId: state.pathParameters['trackingId'] ?? '',
                          fallbackRouteName: AppRoutes.clientCasesName,
                        ),
                      ),
                      // Pay an unpaid case: the invoice endpoint resolves the
                      // case id, so the screen opens by it. No tracking card —
                      // the user is already inside Cases.
                      GoRoute(
                        path: 'pay',
                        name: AppRoutes.clientCasePayName,
                        builder: (context, state) => InvoiceScreen(
                          invoiceId: state.pathParameters['caseId'] ?? '',
                          trackingId: '',
                          title: 'Invoice',
                        ),
                      ),
                    ],
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
        builder: (context, state, navigationShell) => Consumer(
          builder: (context, ref, _) {
            final canViewStaff =
                ref.watch(sessionProvider)?.permissions.canViewStaff ?? false;
            return AppShell(
              navigationShell: navigationShell,
              tabs: AppShell.staffTabs,
              hiddenBranches: canViewStaff
                  ? const {}
                  : const {AppShell.staffMembersBranch},
            );
          },
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dashboardPath,
                name: AppRoutes.dashboardName,
                builder: (context, state) => const StaffHomeScreen(
                  caseDetailRouteName: AppRoutes.caseDetailName,
                  chatRouteName: AppRoutes.caseChatName,
                  trackingLookupRouteName: AppRoutes.staffTrackingLookupName,
                  casesRouteName: AppRoutes.casesName,
                ),
                routes: [
                  // The tracking lookup moved off the tab root; it is now
                  // reached from the home header's search entry.
                  GoRoute(
                    path: 'lookup',
                    name: AppRoutes.staffTrackingLookupName,
                    builder: (context, state) => const DashboardScreen(
                      progressRouteName: AppRoutes.trackingProgressName,
                      searchPropertyRouteName:
                          AppRoutes.staffSearchPropertyName,
                    ),
                  ),
                  GoRoute(
                    path: 'track/:trackingId',
                    name: AppRoutes.trackingProgressName,
                    builder: (context, state) => TrackingProgressScreen(
                      trackingId: state.pathParameters['trackingId'] ?? '',
                      fallbackRouteName: AppRoutes.staffTrackingLookupName,
                    ),
                  ),
                  GoRoute(
                    path: 'search-property',
                    name: AppRoutes.staffSearchPropertyName,
                    builder: (context, state) => const SearchPropertyScreen(
                      quoteRouteName: AppRoutes.staffSearchQuoteName,
                    ),
                  ),
                  GoRoute(
                    path: 'quote/:invoiceId',
                    name: AppRoutes.staffSearchQuoteName,
                    builder: (context, state) => _quote(
                      state,
                      trackRouteName: AppRoutes.trackingProgressName,
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
                  chatRouteName: AppRoutes.caseChatName,
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
                      chatRouteName: AppRoutes.caseChatName,
                      disputeRouteName: AppRoutes.staffDisputeName,
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

/// The cost of a search just filed, in either role's branch.
Widget _quote(GoRouterState state, {required String trackRouteName}) =>
    InvoiceScreen(
      invoiceId: state.pathParameters['invoiceId'] ?? '',
      trackingId: state.uri.queryParameters['trackingId'] ?? '',
      trackRouteName: trackRouteName,
    );

/// One dispute; the same screen for both roles, which answers by session.
Widget _dispute(GoRouterState state) => DisputeDetailScreen(
  caseId: state.pathParameters['caseId'] ?? '',
  disputeId: state.pathParameters['disputeId'] ?? '',
);

/// Both roles' Profile tab until the profile screen is designed. Carries the
/// only way to sign out meanwhile.
class _ProfilePlaceholder extends StatelessWidget {
  const _ProfilePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Profile',
      message: 'Your account details will appear here.',
      action: SignOutButton(),
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
