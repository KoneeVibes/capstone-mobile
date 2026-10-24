import 'staff_role.dart';

/// What a staff role may do in the app. The one place the rules live — the
/// UI asks this, never the role itself.
///
/// It only decides what is shown; the backend enforces the same rules.
/// Agreed 6 Oct 2026; case actions from the Case Status Matrix, 24 Oct 2026.
class StaffPermissions {
  const StaffPermissions(this.role);

  /// Clients, and staff whose role is not known yet.
  static const none = StaffPermissions(null);

  final StaffRole? role;

  /// The Staff tab, and the `GET /staff` list behind it.
  bool get canViewStaff =>
      _isAny(const {StaffRole.superAdmin, StaffRole.admin, StaffRole.manager});

  bool get canCreateStaff =>
      _isAny(const {StaffRole.superAdmin, StaffRole.admin});

  /// Editing includes changing the member's role.
  bool get canEditStaff =>
      _isAny(const {StaffRole.superAdmin, StaffRole.admin, StaffRole.manager});

  bool get canDeleteStaff => role == StaffRole.superAdmin;

  /// Assign and re-assign. Same roles as [canViewStaff]: the picker lists
  /// `GET /staff`, which regular cannot read.
  bool get canAssignCases => canViewStaff;

  /// Taking a suspended case off its holder. Super-admin only.
  bool get canReassignSuspendedCases => role == StaffRole.superAdmin;

  bool get canSuspendCases => role == StaffRole.superAdmin;

  /// Accepting a submitted report, which closes the case.
  bool get canReviewReports => role == StaffRole.superAdmin;

  /// Requesting information on a case someone else holds. The matrix gives it
  /// to the assignee's manager, but no record says who that is, so it goes to
  /// every manager and the backend decides (ADR 0019).
  bool get canRequestCaseInformation => role == StaffRole.manager;

  bool _isAny(Set<StaffRole> roles) => roles.contains(role);
}
