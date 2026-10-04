/// Route names and paths.
///
/// Navigate by name (`context.goNamed(AppRoutes.staffMembersName)`) so a path
/// change never has to be chased through the widget tree.
abstract final class AppRoutes {
  const AppRoutes._();

  /// The app's entry point. Holds the brand mark while the app starts, then
  /// hands off to [rootPath].
  static const String splashName = 'splash';
  static const String splashPath = '/splash';

  /// Where the splash hands off. Redirects to the branch matching the
  /// signed-in role.
  static const String rootName = 'root';
  static const String rootPath = '/';

  // Client branch. `/client` redirects to the home tab.
  static const String clientRootName = 'clientRoot';
  static const String clientRootPath = '/client';

  static const String clientHomeName = 'clientHome';
  static const String clientHomePath = '/client/home';

  static const String clientSearchName = 'clientSearch';
  static const String clientSearchPath = '/client/search';

  static const String clientCasesName = 'clientCases';
  static const String clientCasesPath = '/client/cases';

  /// Takes a `caseId` path parameter.
  static const String clientCaseDetailName = 'clientCaseDetail';
  static const String clientCaseDetailPath = '/client/cases/:caseId';

  static const String clientProfileName = 'clientProfile';
  static const String clientProfilePath = '/client/profile';

  // Staff branch. `/staff` redirects to the dashboard tab.
  static const String staffHomeName = 'staffHome';
  static const String staffHomePath = '/staff';

  static const String dashboardName = 'dashboard';
  static const String dashboardPath = '/staff/dashboard';

  /// Takes a `trackingId` path parameter.
  static const String trackingProgressName = 'trackingProgress';
  static const String trackingProgressPath = '/staff/dashboard/track/:trackingId';

  static const String staffMembersName = 'staffMembers';
  static const String staffMembersPath = '/staff/members';

  static const String casesName = 'cases';
  static const String casesPath = '/staff/cases';

  /// Takes a `caseId` path parameter.
  static const String caseDetailName = 'caseDetail';
  static const String caseDetailPath = '/staff/cases/:caseId';

  static const String staffProfileName = 'staffProfile';
  static const String staffProfilePath = '/staff/profile';

  // Legal. Screens land with the legal-content task; the paths are fixed now so
  // links from other screens can be written against them.
  static const String privacyPolicyName = 'privacyPolicy';
  static const String privacyPolicyPath = '/legal/privacy-policy';

  static const String termsName = 'terms';
  static const String termsPath = '/legal/terms';
}
