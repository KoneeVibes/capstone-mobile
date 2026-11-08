import 'package:flutter_test/flutter_test.dart';
import 'package:propertyintelmobileapp/features/dashboard/data/models/tracked_case_model.dart';

import '../../dashboard_fixtures.dart';

void main() {
  final tracked = TrackedCaseModel.fromData(trackingJson);

  test('only a later assignment counts as a re-assignment', () {
    expect(tracked.isReassignment(1), isFalse);
    expect(tracked.isReassignment(2), isFalse);
    expect(tracked.isReassignment(3), isTrue);
  });
}
