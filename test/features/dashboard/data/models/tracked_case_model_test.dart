import 'package:flutter_test/flutter_test.dart';
import 'package:propertyintelmobileapp/features/dashboard/data/models/case_address_model.dart';
import 'package:propertyintelmobileapp/features/dashboard/data/models/staff_name_model.dart';
import 'package:propertyintelmobileapp/features/dashboard/data/models/tracked_case_model.dart';
import 'package:propertyintelmobileapp/features/dashboard/domain/entities/tracking_status.dart';

import '../../dashboard_fixtures.dart';

void main() {
  group('TrackedCaseModel.fromData', () {
    test('decodes the live response', () {
      final tracked = TrackedCaseModel.fromData(trackingJson);

      expect(tracked.trackingId, 'PI-URF8T7C2');
      expect(tracked.status, TrackingStatus.assigned);
      expect(tracked.updatedAt, DateTime.utc(2026, 8, 31, 19, 17, 38, 580));
      expect(tracked.address, isNull);
      expect(tracked.history.map((e) => e.status), [
        TrackingStatus.submitted,
        TrackingStatus.paymentValidated,
        TrackingStatus.assigned,
        TrackingStatus.assigned,
      ]);
    });

    test('keeps null assignee ids and notes as null', () {
      final history = TrackedCaseModel.fromData(trackingJson).history;

      expect(history.first.assigneeId, isNull);
      expect(history.first.note, 'Case submitted successfully.');
      expect(history[2].assigneeId, 'staff-1');
      expect(history[2].note, isNull);
    });

    test('tolerates a missing history and an unknown status', () {
      final tracked = TrackedCaseModel.fromData(const {
        'trackingId': 'PI-X',
        'status': 'archived',
      });

      expect(tracked.status, TrackingStatus.unknown);
      expect(tracked.history, isEmpty);
    });

    test('rejects a body that is not an object', () {
      expect(() => TrackedCaseModel.fromData(const []), throwsFormatException);
    });
  });

  group('CaseAddressModel', () {
    test('prefers the street address', () {
      final row = CaseAddressModel.fromJson(caseRowJson());

      expect(row.trackingId, 'PI-URF8T7C2');
      expect(row.address, '5 Kayode Abraham, Off Ligali Ayorinde');
    });

    test('falls back to city and state', () {
      final row = CaseAddressModel.fromJson(caseRowJson(address: ''));

      expect(row.address, 'Victoria Island, Lagos');
    });
  });

  test('StaffNameModel joins first and last name', () {
    final person = StaffNameModel.fromJson(staffRowJson());

    expect(person.id, 'staff-1');
    expect(person.name, 'Ada Okafor');
  });
}
