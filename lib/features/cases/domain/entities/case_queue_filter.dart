import 'case.dart';
import 'case_status.dart';

/// The tabs above the staff home's "My queue". Each groups several statuses so
/// the row fits on a phone; the Cases tab keeps one per status.
enum CaseQueueFilter {
  all,

  /// Waiting to be paid for or handed out.
  fresh,

  /// With someone, and still moving — a disputed case included, since its
  /// report is being redone.
  assigned,

  /// Finished or halted.
  closed;

  /// A status this build does not know shows under [all] only.
  bool matches(Case value) => switch (this) {
    all => true,
    fresh =>
      value.status == CaseStatus.submitted ||
          value.status == CaseStatus.paymentValidated,
    assigned =>
      value.status == CaseStatus.assigned ||
          value.status == CaseStatus.accepted ||
          value.status == CaseStatus.pendingInformation ||
          value.status == CaseStatus.underReview ||
          value.status == CaseStatus.disputed,
    closed =>
      value.status == CaseStatus.closed || value.status == CaseStatus.suspended,
  };

  /// The first [limit] cases under this tab, most recently changed first.
  List<Case> pick(Iterable<Case> cases, {required int limit}) {
    final matching = cases.where(matches).toList()
      ..sort((a, b) => _changed(b).compareTo(_changed(a)));
    return matching.take(limit).toList();
  }

  /// When the case last moved; one with no dates sorts last.
  static DateTime _changed(Case value) =>
      value.updatedAt ??
      value.createdAt ??
      DateTime.fromMillisecondsSinceEpoch(0);
}
