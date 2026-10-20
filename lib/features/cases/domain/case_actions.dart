import '../../../core/session/staff_permissions.dart';
import 'entities/case.dart';
import 'entities/case_status.dart';

/// Everything a staff member can do to a case from the Cases screens.
///
/// [accept], [suspend], [reviewReport] and [addReport] are mock until their
/// endpoints land (ADR 0017); [assign] and [reassign] write for real.
enum CaseAction {
  /// Open the case conversation.
  requestInformation,
  assign,
  reassign,
  reviewReport,
  accept,
  suspend,
  addReport,
}

/// The button a case card shows, and whether it is live.
class CaseCardAction {
  const CaseCardAction(this.action, {this.isEnabled = true});

  final CaseAction action;
  final bool isEnabled;
}

/// Who is looking at a case, as far as the action rules care.
class CaseViewer {
  const CaseViewer({required this.permissions, required this.userId});

  final StaffPermissions permissions;

  /// The signed-in staff member's id, compared with the case's assignee.
  final String? userId;

  bool isAssigneeOf(Case value) => userId != null && value.assigneeId == userId;
}

/// The ⋮ menu on the staff case detail, in the order the design lists them.
List<CaseAction> menuActionsFor(Case value, CaseViewer viewer) {
  final canManage = viewer.permissions.canAssignCases;
  final status = value.status;
  final canAssign = canManage && status.canBeAssigned;

  return [
    CaseAction.requestInformation,
    if (canAssign && value.isAssigned) CaseAction.reassign,
    if (canAssign && !value.isAssigned) CaseAction.assign,
    if (canManage && status == CaseStatus.underReview) CaseAction.reviewReport,
    if (status == CaseStatus.assigned && viewer.isAssigneeOf(value))
      CaseAction.accept,
    if (canManage && status.canBeSuspended) CaseAction.suspend,
  ];
}

/// The one button on a staff case card, or null for none.
///
/// Mirrors the queue's status-to-action map, filtered by what the viewer may
/// do: a member without assign rights sees no assign button rather than a
/// disabled one they could never use.
CaseCardAction? cardActionFor(Case value, CaseViewer viewer) {
  final canManage = viewer.permissions.canAssignCases;

  return switch (value.status) {
    // Shown greyed out: the case is the manager's next job once paid.
    CaseStatus.submitted when canManage => const CaseCardAction(
      CaseAction.assign,
      isEnabled: false,
    ),
    CaseStatus.paymentValidated when canManage => CaseCardAction(
      value.isAssigned ? CaseAction.reassign : CaseAction.assign,
    ),
    CaseStatus.assigned when viewer.isAssigneeOf(value) => const CaseCardAction(
      CaseAction.accept,
    ),
    CaseStatus.assigned when canManage => const CaseCardAction(
      CaseAction.reassign,
    ),
    CaseStatus.accepted => const CaseCardAction(CaseAction.addReport),
    CaseStatus.underReview when canManage => const CaseCardAction(
      CaseAction.reviewReport,
    ),
    CaseStatus.pendingInformation => const CaseCardAction(
      CaseAction.requestInformation,
    ),
    CaseStatus.closed || CaseStatus.suspended when canManage => CaseCardAction(
      value.isAssigned ? CaseAction.reassign : CaseAction.assign,
    ),
    _ => null,
  };
}
