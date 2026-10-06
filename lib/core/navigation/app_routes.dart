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

  // Signed out. Everything under these is reachable without a session.
  static const String onboardingName = 'onboarding';
  static const String onboardingPath = '/onboarding';

  static const String loginName = 'login';
  static const String loginPath = '/login';

  static const String registerName = 'register';
  static const String registerPath = '/register';

  static const String registerVerifyName = 'registerVerify';
  static const String registerVerifyPath = '/register/verify';

  static const String forgotPasswordName = 'forgotPassword';
  static const String forgotPasswordPath = '/forgot-password';

  static const String forgotPasswordVerifyName = 'forgotPasswordVerify';
  static const String forgotPasswordVerifyPath = '/forgot-password/verify';

  static const String resetPasswordName = 'resetPassword';
  static const String resetPasswordPath = '/forgot-password/reset';

  static const String passwordChangedName = 'passwordChanged';
  static const String passwordChangedPath = '/forgot-password/done';

  // Client branch. `/client` redirects to the home tab.
  static const String clientRootName = 'clientRoot';
  static const String clientRootPath = '/client';

  static const String clientHomeName = 'clientHome';
  static const String clientHomePath = '/client/home';

  static const String clientSearchName = 'clientSearch';
  static const String clientSearchPath = '/client/search';

  /// Takes a `trackingId` path parameter.
  static const String clientTrackingProgressName = 'clientTrackingProgress';
  static const String clientTrackingProgressPath =
      '/client/search/track/:trackingId';

  static const String clientSearchPropertyName = 'clientSearchProperty';
  static const String clientSearchPropertyPath = '/client/search/property';

  /// Takes an `invoiceId` path parameter and a `trackingId` query parameter.
  /// A sibling of the form, not under it, so replacing the form leaves no
  /// filled-in copy behind.
  static const String clientSearchQuoteName = 'clientSearchQuote';
  static const String clientSearchQuotePath = '/client/search/quote/:invoiceId';

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
  static const String trackingProgressPath =
      '/staff/dashboard/track/:trackingId';

  static const String staffSearchPropertyName = 'staffSearchProperty';
  static const String staffSearchPropertyPath =
      '/staff/dashboard/search-property';

  /// As [clientSearchQuoteName].
  static const String staffSearchQuoteName = 'staffSearchQuote';
  static const String staffSearchQuotePath =
      '/staff/dashboard/quote/:invoiceId';

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
