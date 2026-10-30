import '../../../core/session/staff_permissions.dart';
import 'entities/case.dart';
import 'entities/case_dispute.dart';
import 'entities/case_status.dart';

/// Everything a staff member can do to a case from the Cases screens and the
/// home queue. All write for real except [requestInformation], which opens
/// the mock chat (ADR 0019).
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

/// Who is looking at a case, and what the Case Status Matrix lets them do to
/// it (ADR 0019). The menu, the card button and the detail footer all ask
/// these, so the rules live nowhere else.
class CaseViewer {
  const CaseViewer({required this.permissions, required this.userId});

  final StaffPermissions permissions;

  /// The signed-in staff member's id, compared with the case's assignee.
  final String? userId;

  bool isAssigneeOf(Case value) => userId != null && value.assigneeId == userId;

  /// Assign or reassign, whichever the case needs. Taking a suspended case
  /// off its holder needs a super-admin.
  bool canHandOver(Case value) =>
      permissions.canAssignCases &&
      value.status.canBeAssigned &&
      (value.status != CaseStatus.suspended ||
          permissions.canReassignSuspendedCases);

  bool canAccept(Case value) =>
      value.status == CaseStatus.assigned && isAssigneeOf(value);

  bool canSuspend(Case value) =>
      permissions.canSuspendCases && value.status.canBeSuspended;

  bool canReviewReport(Case value) =>
      permissions.canReviewReports && value.status == CaseStatus.underReview;

  bool canRequestInformation(Case value) =>
      value.status.opensConversation &&
      (isAssigneeOf(value) || permissions.canRequestCaseInformation);

  /// Only the assignee ever submits a report.
  bool canAddReport(Case value) =>
      isAssigneeOf(value) && value.status.takesReport;

  /// Take [dispute] in: the assignee only ("Only the assigned staff member
  /// may accept the dispute", checked live 28 Oct 2026; ADR 0025).
  bool canAcceptDispute(Case value, CaseDispute dispute) =>
      _isAnswerable(value, dispute) && isAssigneeOf(value);

  /// Decline [dispute] with a note: the assignee or their manager. A manager
  /// only sees their own team's cases, so any manager here is theirs (0026).
  bool canDeclineDispute(Case value, CaseDispute dispute) =>
      _isAnswerable(value, dispute) &&
      (isAssigneeOf(value) || permissions.canRespondToDisputes);

  /// Open, on a case still closed. Once taken in the case is `disputed`, so a
  /// dispute the server left open cannot be answered twice.
  bool _isAnswerable(Case value, CaseDispute dispute) =>
      dispute.isOpen && value.status.canBeDisputed;
}

/// The ⋮ menu on the staff case detail, in the order the design lists them.
/// Empty when the viewer can do nothing to this case.
List<CaseAction> menuActionsFor(Case value, CaseViewer viewer) => [
  if (viewer.canRequestInformation(value)) CaseAction.requestInformation,
  if (viewer.canHandOver(value))
    value.isAssigned ? CaseAction.reassign : CaseAction.assign,
  if (viewer.canReviewReport(value)) CaseAction.reviewReport,
  if (viewer.canAccept(value)) CaseAction.accept,
  if (viewer.canSuspend(value)) CaseAction.suspend,
];

/// The one button on a staff case card, or null for none.
///
/// The viewer's own next step wins over a manager's: an assignee who is also a
/// manager sees Accept, not Reassign. A member sees no button they could not
/// use. Suspend is never a card button.
CaseCardAction? cardActionFor(Case value, CaseViewer viewer) {
  // Shown greyed out: the case is the manager's next job once paid.
  if (value.status.isAwaitingPayment) {
    return viewer.permissions.canAssignCases
        ? const CaseCardAction(CaseAction.assign, isEnabled: false)
        : null;
  }

  final action = switch (value) {
    _ when viewer.canAccept(value) => CaseAction.accept,
    _ when viewer.canReviewReport(value) => CaseAction.reviewReport,
    // Under review the report is already in; replacing it is a detail job.
    _
        when viewer.canAddReport(value) &&
            value.status != CaseStatus.underReview =>
      CaseAction.addReport,
    _ when viewer.canHandOver(value) =>
      value.isAssigned ? CaseAction.reassign : CaseAction.assign,
    _ when viewer.canRequestInformation(value) => CaseAction.requestInformation,
    _ => null,
  };
  return action == null ? null : CaseCardAction(action);
}
