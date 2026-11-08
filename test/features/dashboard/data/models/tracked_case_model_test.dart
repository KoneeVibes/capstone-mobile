import 'package:flutter_test/flutter_test.dart';
import 'package:propertyintelmobileapp/features/dashboard/data/models/recent_search_model.dart';
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
      expect(tracked.address, '5 Kayode Abraham, Off Ligali Ayorinde');
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

    test('reads the assignee names the server sends', () {
      final history = TrackedCaseModel.fromData(trackingJson).history;

      expect(history[1].assigneeName, isNull);
      expect(history[2].assigneeName, 'Ada Okafor Regular');
      expect(history[3].assigneeName, isNull);
    });

    test('tolerates a missing history and an unknown status', () {
      final tracked = TrackedCaseModel.fromData(const {
        'trackingId': 'PI-X',
        'status': 'archived',
      });

      expect(tracked.status, TrackingStatus.unknown);
      expect(tracked.address, isNull);
      expect(tracked.history, isEmpty);
    });

    test('rejects a body that is not an object', () {
      expect(() => TrackedCaseModel.fromData(const []), throwsFormatException);
    });
  });

  group('RecentSearchModel.listFromJson', () {
    test('decodes the live record', () {
      expect(RecentSearchModel.listFromJson([historyJson()]), [
        RecentSearchModel(
          id: '174160f3-a7fa-49d5-b97c-673ec3acba90',
          trackingId: 'PI-8APCC9W3',
          searchedAt: DateTime.utc(2026, 11, 8, 7, 2, 57, 19),
        ),
      ]);
    });

    test('keeps tracking IDs only, normalised', () {
      final searches = RecentSearchModel.listFromJson([
        historyJson(id: 'a', query: 'Lagos'),
        historyJson(id: 'b', query: 'pi-urf8t7c2'),
        historyJson(id: 'c', query: 'PI-SHORT'),
      ]);

      expect(searches.map((s) => (s.id, s.trackingId)), [('b', 'PI-URF8T7C2')]);
    });

    test('lists a tracking ID once, at its newest', () {
      final searches = RecentSearchModel.listFromJson([
        historyJson(id: 'new', query: 'PI-URF8T7C2'),
        historyJson(id: 'other'),
        historyJson(id: 'old', query: 'urf8t7c2'),
      ]);

      expect(searches.map((s) => s.id), ['new', 'other']);
    });

    test('tolerates a body that is not a list', () {
      expect(RecentSearchModel.listFromJson(null), isEmpty);
    });
  });
}
