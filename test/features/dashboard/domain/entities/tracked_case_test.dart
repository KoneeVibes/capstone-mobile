import 'package:flutter_test/flutter_test.dart';
import 'package:propertyintelmobileapp/features/dashboard/data/models/tracked_case_model.dart';
import 'package:propertyintelmobileapp/features/dashboard/domain/entities/recent_search.dart';
import 'package:propertyintelmobileapp/features/dashboard/domain/entities/tracking_status.dart';

import '../../dashboard_fixtures.dart';

void main() {
  final tracked = TrackedCaseModel.fromData(trackingJson);

  test('assigneeIds collects every distinct assignee in the history', () {
    expect(tracked.assigneeIds, {'staff-1', 'staff-2'});
  });

  test('only a later assignment counts as a re-assignment', () {
    expect(tracked.isReassignment(1), isFalse);
    expect(tracked.isReassignment(2), isFalse);
    expect(tracked.isReassignment(3), isTrue);
  });

  test('withDetails joins the address and the names it can resolve', () {
    final detailed = tracked.withDetails(
      address: '5 Kayode Abraham',
      assigneeNames: const {'staff-1': 'Ada Okafor'},
    );

    expect(detailed.address, '5 Kayode Abraham');
    expect(detailed.history[2].assigneeName, 'Ada Okafor');
    expect(detailed.history[3].assigneeName, isNull);
    expect(detailed.history[3].assigneeId, 'staff-2');
  });

  test('RecentSearch captures the case as it stood', () {
    final search = RecentSearch.fromTracked(
      tracked.withDetails(address: '5 Kayode Abraham'),
    );

    expect(
      search,
      const RecentSearch(
        trackingId: 'PI-URF8T7C2',
        status: TrackingStatus.assigned,
        address: '5 Kayode Abraham',
      ),
    );
  });
}
