/// Where a case sits in its lifecycle.
///
/// Owned by the backend: these are the nine values `GET /api/v1/case` returns.
/// The getters below say what a status allows, from the Case Status Matrix
/// (ADR 0019); who may do it is decided in `case_actions.dart`.
enum CaseStatus {
  /// Raised by an applicant, with payment not yet validated.
  submitted('submitted'),

  /// Payment cleared, waiting for someone to be given it.
  paymentValidated('payment-validated'),

  /// Given to a team member, who has not accepted it yet.
  assigned('assigned'),

  /// Accepted by the team member it was given to.
  accepted('accepted'),

  /// Waiting on more information through an open conversation.
  pendingInformation('pending-information'),

  /// A report is in and waits for a super-admin to accept it. The client
  /// cannot see the report yet.
  underReview('under-review'),

  /// The report was accepted and released to the client.
  closed('closed'),

  /// Halted by a super-admin.
  suspended('suspended'),

  /// The client disputed the outcome and it was taken in; the report has to
  /// be submitted again.
  disputed('disputed'),

  /// A status the API returned that this build does not know about.
  ///
  /// Kept so one unrecognised record cannot break the whole list. See
  /// `StaffStatus.unknown` for the same reasoning.
  unknown('');

  const CaseStatus(this.apiValue);

  /// The exact string the API returns and accepts.
  final String apiValue;

  /// Parses an API value, falling back to [unknown] rather than throwing.
  static CaseStatus fromApi(String? value) {
    if (value == null) return unknown;
    final normalised = value.trim().toLowerCase();
    for (final status in values) {
      if (status != unknown && status.apiValue == normalised) return status;
    }
    return unknown;
  }

  bool get isKnown => this != unknown;

  /// Whether the case can change hands: given out from [paymentValidated],
  /// handed on from [assigned] or [accepted], or (super-admin only) taken off
  /// a [suspended] case. Anything else is mid-review or finished, and the
  /// backend refuses it.
  bool get canBeAssigned =>
      this == paymentValidated ||
      this == assigned ||
      this == accepted ||
      this == suspended;

  /// Filed but not paid for: `payment-validated` is the step after.
  bool get isAwaitingPayment => this == submitted;

  /// Paid and still running. Not a disputed, closed or suspended case.
  bool get canBeSuspended =>
      this == paymentValidated ||
      this == assigned ||
      this == accepted ||
      this == pendingInformation ||
      this == underReview;

  /// Whether information can be requested through the case conversation.
  bool get opensConversation =>
      this == accepted || this == pendingInformation || this == disputed;

  /// Whether the assignee can submit a report, or replace the one under review.
  bool get takesReport =>
      this == accepted || this == underReview || this == disputed;

  /// Whether the client may see the report: only once it has been accepted.
  bool get releasesReport => this == closed;

  /// A client disputes a finished case's outcome: `POST /dispute` takes a
  /// closed case only (ADR 0025).
  bool get canBeDisputed => this == closed;

  /// Whether assigning also moves the case along its lifecycle.
  ///
  /// [paymentValidated] is the hand-off assigning causes, and re-assigning a
  /// [suspended] case lifts the suspension (backend lead, 26 Oct 2026; ADR
  /// 0021). Re-assigning anything else is a change of hands, and sending
  /// `assigned` alongside it would knock the case backwards.
  bool get advancesOnAssign => this == paymentValidated || this == suspended;
}
