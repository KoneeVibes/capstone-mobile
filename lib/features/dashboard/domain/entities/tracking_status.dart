/// A case status as the tracking endpoint reports it.
///
/// Mirrors the cases feature's `CaseStatus` on purpose: features do not import
/// each other, and the dashboard may diverge. Backend values are the truth.
enum TrackingStatus {
  submitted('submitted'),
  paymentValidated('payment-validated'),
  assigned('assigned'),
  accepted('accepted'),
  pendingInformation('pending-information'),
  underReview('under-review'),
  closed('closed'),
  suspended('suspended'),

  /// A value this build does not know; renders rather than breaking the screen.
  unknown('');

  const TrackingStatus(this.apiValue);

  final String apiValue;

  static TrackingStatus fromApi(String? value) {
    final normalised = value?.trim().toLowerCase();
    for (final status in values) {
      if (status != unknown && status.apiValue == normalised) return status;
    }
    return unknown;
  }

  bool get isKnown => this != unknown;
}
