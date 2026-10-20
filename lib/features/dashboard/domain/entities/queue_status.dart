/// Where a queued case sits, as the staff home draws it.
///
/// A superset of the cases feature's `CaseStatus`: it carries the same eight
/// lifecycle values plus [disputed], a state the backend does not expose yet
/// (the team's upcoming case flows add it). Dashboard-local on purpose —
/// features do not import each other, and this view may keep diverging. Mirrors
/// the precedent set by `TrackingStatus`.
///
/// TODO(backend): replace with the real status the staff-queue endpoint returns.
enum QueueStatus {
  paymentValidated,
  submitted,
  assigned,
  accepted,
  pendingInformation,
  underReview,
  closed,
  suspended,

  /// New with the upcoming case flows; no server value yet.
  disputed,
}
