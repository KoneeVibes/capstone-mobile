/// Where a case sits in its lifecycle.
///
/// Owned by the backend and verified against the live API: these are the six
/// values `GET /api/v1/case`'s `filter` parameter accepts. The app reads a
/// status freely but writes only one — `assigned`, when it hands an untouched
/// case to someone. Every other transition happens elsewhere.
enum CaseStatus {
  /// Raised by an applicant, not yet given to anyone. The New tab.
  submitted('submitted'),

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

  /// Nobody has been given it yet — the one state the app moves a case out of.
  ///
  /// Also decides whether an assignment writes a status at all: assigning a
  /// [submitted] case advances it, while assigning any other case is only a
  /// change of hands and must leave the status alone.
  bool get isSubmitted => this == submitted;

  /// Whether the case is in someone's hands.
  ///
  /// Four statuses mean that, which is why the Assigned tab is a bucket rather
  /// than an equality check. A case waiting on the applicant still belongs to
  /// whoever is chasing them, so it belongs in the bucket too.
  bool get isWithSomeone =>
      this == assigned ||
      this == accepted ||
      this == pendingInformation ||
      this == underReview;

  bool get isClosed => this == closed;
}
