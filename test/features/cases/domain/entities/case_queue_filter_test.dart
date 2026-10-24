import 'package:flutter_test/flutter_test.dart';
import 'package:propertyintelmobileapp/features/cases/domain/entities/case_queue_filter.dart';
import 'package:propertyintelmobileapp/features/cases/domain/entities/case_status.dart';

import '../../case_fixtures.dart';

void main() {
  group('matches', () {
    test('every known status sits under exactly one tab besides All', () {
      for (final status in CaseStatus.values.where((s) => s.isKnown)) {
        final tabs = CaseQueueFilter.values
            .where((filter) => filter != CaseQueueFilter.all)
            .where((filter) => filter.matches(buildCase(status: status)));
        expect(tabs, hasLength(1), reason: '$status');
      }
    });

    test('a disputed case counts as still being worked', () {
      expect(
        CaseQueueFilter.assigned.matches(
          buildCase(status: CaseStatus.disputed),
        ),
        isTrue,
      );
    });

    test('an unknown status shows under All only', () {
      final value = buildCase(status: CaseStatus.unknown);
      expect(CaseQueueFilter.values.where((filter) => filter.matches(value)), [
        CaseQueueFilter.all,
      ]);
    });
  });

  group('pick', () {
    test('most recently changed first, up to the limit', () {
      final cases = [
        for (var day = 1; day <= 7; day++)
          buildCase(id: 'case-$day', updatedAt: DateTime(2026, 10, day)),
      ];

      final picked = CaseQueueFilter.all.pick(cases, limit: 5);

      expect(picked.map((value) => value.id), [
        'case-7',
        'case-6',
        'case-5',
        'case-4',
        'case-3',
      ]);
    });

    test('falls back to the filing date, and undated cases sort last', () {
      final cases = [
        buildCase(id: 'undated'),
        buildCase(id: 'filed', createdAt: DateTime(2026, 10, 2)),
        buildCase(id: 'moved', updatedAt: DateTime(2026, 10, 3)),
      ];

      expect(
        CaseQueueFilter.all.pick(cases, limit: 5).map((value) => value.id),
        ['moved', 'filed', 'undated'],
      );
    });

    test('takes only what the tab admits', () {
      final cases = [
        buildCase(id: 'new'),
        buildCase(id: 'done', status: CaseStatus.closed),
      ];

      expect(
        CaseQueueFilter.closed.pick(cases, limit: 5).map((value) => value.id),
        ['done'],
      );
    });
  });
}
