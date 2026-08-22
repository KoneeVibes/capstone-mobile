/// Route names and paths.
///
/// Navigate by name (`context.goNamed(AppRoutes.staffMembersName)`) so a path
/// change never has to be chased through the widget tree.
abstract final class AppRoutes {
  const AppRoutes._();

  /// Entry point. Redirects to the branch matching the signed-in role.
  static const String rootName = 'root';
  static const String rootPath = '/';

  // Client branch.
  static const String clientHomeName = 'clientHome';
  static const String clientHomePath = '/client';

  // Staff branch.
  static const String staffHomeName = 'staffHome';
  static const String staffHomePath = '/staff';

  static const String staffMembersName = 'staffMembers';
  static const String staffMembersPath = '/staff/members';

  static const String casesName = 'cases';
  static const String casesPath = '/staff/cases';

  /// Takes a `caseId` path parameter.
  static const String caseDetailName = 'caseDetail';
  static const String caseDetailPath = '/staff/cases/:caseId';

  // Legal. Screens land with the legal-content task; the paths are fixed now so
  // links from other screens can be written against them.
  static const String privacyPolicyName = 'privacyPolicy';
  static const String privacyPolicyPath = '/legal/privacy-policy';

  static const String termsName = 'terms';
  static const String termsPath = '/legal/terms';
}
