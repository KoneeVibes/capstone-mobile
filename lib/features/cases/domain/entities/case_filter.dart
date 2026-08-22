import 'case.dart';
import 'case_status.dart';

/// The tabs above the cases list.
///
/// Not a mirror of [CaseStatus], which has six values to these four tabs:
/// [assigned] is a bucket covering everything somebody already holds
/// (`assigned`, `accepted`, `pending-information`, `under-review`), because
/// from the list's point of view they are the same thing. Keeping the rule here
/// rather than in the screen means the list and its tests agree on what each
/// tab means.
enum CaseFilter {
  all,
  newCases,
  assigned,
  closed;

  bool matches(Case value) => switch (this) {
    CaseFilter.all => true,
    CaseFilter.newCases => value.status.isSubmitted,
    CaseFilter.assigned => value.status.isWithSomeone,
    CaseFilter.closed => value.status.isClosed,
  };
}
