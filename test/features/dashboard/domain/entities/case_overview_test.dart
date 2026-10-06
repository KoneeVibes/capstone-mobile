import 'package:flutter_test/flutter_test.dart';
import 'package:propertyintelmobileapp/features/dashboard/domain/entities/case_overview.dart';
import 'package:propertyintelmobileapp/features/dashboard/domain/entities/tracking_status.dart';

void main() {
  test('every status lands in exactly the card agreed for it', () {
    final overview = CaseOverview.fromStatuses(TrackingStatus.values);

    expect(overview.total, TrackingStatus.values.length);
    expect(overview.reportsReady, 1); // closed
    // payment-validated, assigned, accepted, under-review.
    expect(overview.inProgress, 4);
    // submitted (unpaid) and pending-information.
    expect(overview.needsInput, 2);
  });

  test('suspended and unknown count only towards the total', () {
    final overview = CaseOverview.fromStatuses(const [
      TrackingStatus.suspended,
      TrackingStatus.unknown,
    ]);

    expect(
      overview,
      const CaseOverview(
        total: 2,
        reportsReady: 0,
        inProgress: 0,
        needsInput: 0,
      ),
    );
  });
}
