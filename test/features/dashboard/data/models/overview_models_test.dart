import 'package:flutter_test/flutter_test.dart';
import 'package:propertyintelmobileapp/features/dashboard/data/models/case_overview_model.dart';
import 'package:propertyintelmobileapp/features/dashboard/data/models/queue_overview_model.dart';
import 'package:propertyintelmobileapp/features/dashboard/domain/entities/case_overview.dart';
import 'package:propertyintelmobileapp/features/dashboard/domain/entities/queue_overview.dart';

void main() {
  group('CaseOverviewModel', () {
    test('maps the four client counts', () {
      expect(
        CaseOverviewModel.fromData({
          'totalSearches': 8,
          'reportsReady': 2,
          'inProgress': 5,
          'needsYourInput': 1,
        }),
        const CaseOverview(
          total: 8,
          reportsReady: 2,
          inProgress: 5,
          needsInput: 1,
        ),
      );
    });

    test('reads a missing, negative or non-numeric count as zero', () {
      expect(
        CaseOverviewModel.fromData({
          'totalSearches': 3.0,
          'reportsReady': -1,
          'inProgress': '2',
        }),
        const CaseOverview(
          total: 3,
          reportsReady: 0,
          inProgress: 0,
          needsInput: 0,
        ),
      );
    });

    test('throws when data is not an object', () {
      expect(
        () => CaseOverviewModel.fromData(const <Object>[]),
        throwsFormatException,
      );
    });
  });

  group('QueueOverviewModel', () {
    test('maps queue and recent', () {
      expect(
        QueueOverviewModel.fromData({'queue': 12, 'recent': 4}),
        const QueueOverview(inQueue: 12, assignedThisWeek: 4),
      );
    });

    test('reads a missing count as zero', () {
      expect(
        QueueOverviewModel.fromData({'queue': 1}),
        const QueueOverview(inQueue: 1, assignedThisWeek: 0),
      );
    });

    test('throws when data is not an object', () {
      expect(() => QueueOverviewModel.fromData(null), throwsFormatException);
    });
  });
}
