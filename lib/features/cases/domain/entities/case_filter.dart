import 'case.dart';
import 'case_status.dart';

/// The tabs above the cases list: All, then one per status.
///
/// A tab means exactly one status, so nothing is bucketed and no case appears
/// under two tabs. A case whose status this build does not recognise shows
/// under [all] alone — it has no tab of its own, and inventing one would name a
/// status the app cannot label.
enum CaseFilter {
  all(null),
  submitted(CaseStatus.submitted),
  paymentValidated(CaseStatus.paymentValidated),
  assigned(CaseStatus.assigned),
  accepted(CaseStatus.accepted),
  pendingInformation(CaseStatus.pendingInformation),
  underReview(CaseStatus.underReview),
  closed(CaseStatus.closed),
  suspended(CaseStatus.suspended);

  const CaseFilter(this.status);

  /// The status this tab shows, or null for [all].
  final CaseStatus? status;

  bool matches(Case value) => status == null || value.status == status;
}
