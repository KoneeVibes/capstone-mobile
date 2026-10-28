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

  /// Whether [target]'s row offers Edit, which includes changing their role.
  /// Only a super-admin edits a super-admin; a manager edits regular and
  /// manager rows only (ADR 0024).
  bool canEditStaffMember(StaffRole target) => switch (role) {
    StaffRole.superAdmin => true,
    StaffRole.admin => target != StaffRole.superAdmin,
    StaffRole.manager => grantableRoles.contains(target),
    _ => false,
  };

  /// The roles this user may give someone in the staff form, so nobody can
  /// move a member to a row they could not then edit.
  List<StaffRole> get grantableRoles => switch (role) {
    StaffRole.superAdmin || StaffRole.admin => StaffRole.assignable,
    StaffRole.manager => const [StaffRole.manager, StaffRole.regular],
    _ => const [],
  };

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

  /// Declining a dispute on a case someone else holds. The matrix gives it to
  /// the assignee's manager; as above, every manager (ADR 0025). Accepting
  /// one is the assignee's alone.
  bool get canRespondToDisputes => role == StaffRole.manager;

  bool _isAny(Set<StaffRole> roles) => roles.contains(role);
}
