/// Where a case sits in its lifecycle.
///
/// Owned by the backend: these are the eight values `GET /api/v1/case` returns.
/// The app reads a status freely but writes only one — `assigned`, when it
/// hands a payment-validated case to someone. Every other transition happens
/// elsewhere.
enum CaseStatus {
  /// Raised by an applicant, with payment not yet validated. The one status
  /// the app cannot assign from.
  submitted('submitted'),

  /// Payment cleared, waiting for someone to be given it.
  paymentValidated('payment-validated'),

  /// Given to a team member, who has not picked it up yet.
  assigned('assigned'),

  /// Picked up by the team member it was given to.
  accepted('accepted'),

  /// Stalled: the team is waiting on something from the applicant.
  pendingInformation('pending-information'),

  /// Being worked through.
  underReview('under-review'),

  /// Finished. Still readable, and still re-assignable.
  closed('closed'),

  /// Halted before finishing. Still readable, and still re-assignable.
  suspended('suspended'),

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

  /// Whether the case can be handed to someone, or handed on.
  ///
  /// Everything except [submitted]: a case whose payment has not been validated
  /// is not the team's to pick up yet. Every later status is fair game,
  /// [closed] and [suspended] included — re-assigning one is a change of hands,
  /// not a change of state.
  ///
  /// An [unknown] status is assignable. Refusing there would mean a status
  /// added server-side silently disables the one action this screen has, which
  /// is a worse failure than assigning something we cannot name.
  bool get canBeAssigned => this != submitted;

  /// Filed but not paid for: `payment-validated` is the step after.
  bool get isAwaitingPayment => this == submitted;

  /// Whether assigning also moves the case along its lifecycle.
  ///
  /// Only [paymentValidated] does: that is the hand-off assigning actually
  /// causes. Re-assigning anything further on is a change of hands, and sending
  /// `assigned` alongside it would knock the case backwards.
  bool get advancesOnAssign => this == paymentValidated;
}
