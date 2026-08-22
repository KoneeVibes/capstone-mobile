import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:propertyintelmobileapp/core/utils/error/app_failure.dart';
import 'package:propertyintelmobileapp/core/utils/error/async_value_x.dart';
import 'package:propertyintelmobileapp/core/utils/error/failure_type.dart';
import 'package:propertyintelmobileapp/core/utils/result.dart';
import 'package:propertyintelmobileapp/features/cases/domain/entities/case.dart';
import 'package:propertyintelmobileapp/features/cases/domain/entities/case_filter.dart';
import 'package:propertyintelmobileapp/features/cases/domain/entities/case_status.dart';
import 'package:propertyintelmobileapp/features/cases/domain/repositories/cases_repository.dart';
import 'package:propertyintelmobileapp/features/cases/presentation/providers/cases_list_provider.dart';
import 'package:propertyintelmobileapp/features/cases/presentation/providers/cases_providers.dart';

import '../../case_fixtures.dart';

class MockCasesRepository extends Mock implements CasesRepository {}

Case _case(String id, CaseStatus status) => buildCase(
  id: id,
  status: status,
  assignee: status.isWithSomeone || status.isClosed ? ada : null,
);

/// Something for every tab, including two of the four statuses the Assigned
/// bucket covers.
final _allCases = [
  _case('a', CaseStatus.submitted),
  _case('b', CaseStatus.assigned),
  _case('c', CaseStatus.underReview),
  _case('d', CaseStatus.closed),
  _case('e', CaseStatus.submitted),
];

const _serverFailure = AppFailure(
  type: FailureType.server,
  message: 'Something went wrong on our end. Please try again shortly.',
  statusCode: 500,
);

void main() {
  late MockCasesRepository repository;

  setUp(() => repository = MockCasesRepository());

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [casesRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    return container;
  }

  void stubCases(Result<List<Case>> result) {
    when(repository.fetchCases).thenAnswer((_) async => result);
  }

  group('initial load', () {
    test('exposes every case, on the All tab', () async {
      stubCases(Ok(_allCases));

      final container = makeContainer();
      final state = await container.read(casesListProvider.future);

      expect(state.filter, CaseFilter.all);
      expect(state.items, hasLength(5));
      expect(state.visible, hasLength(5));
      expect(state.isEmpty, isFalse);
    });

    test('reports an empty inbox without erroring', () async {
      stubCases(const Ok([]));

      final container = makeContainer();
      final state = await container.read(casesListProvider.future);

      expect(state.isEmpty, isTrue);
      expect(state.visible, isEmpty);
    });

    test('surfaces a failure as an AppFailure, not a raw error', () async {
      stubCases(const Err(_serverFailure));

      final container = makeContainer();
      // `provider.future` never completes when build() throws, so the errored
      // state is observed through a listener instead.
      final states = <AsyncValue<CasesListState>>[];
      container.listen(
        casesListProvider,
        (_, next) => states.add(next),
        fireImmediately: true,
      );

      await Future<void>.delayed(Duration.zero);

      expect(states.last.hasError, isTrue);
      expect(states.last.failure, _serverFailure);
    });
  });

  group('selectFilter', () {
    test('narrows the visible cases without refetching', () async {
      stubCases(Ok(_allCases));

      final container = makeContainer();
      await container.read(casesListProvider.future);
      final notifier = container.read(casesListProvider.notifier);

      notifier.selectFilter(CaseFilter.newCases);
      expect(
        container.read(casesListProvider).value!.visible.map((c) => c.id),
        ['a', 'e'],
      );

      notifier.selectFilter(CaseFilter.closed);
      expect(
        container.read(casesListProvider).value!.visible.map((c) => c.id),
        ['d'],
      );

      // One fetch for the initial build, and none for either tab switch.
      verify(repository.fetchCases).called(1);
    });

    test('groups every working status under one tab', () async {
      stubCases(Ok(_allCases));

      final container = makeContainer();
      await container.read(casesListProvider.future);
      container
          .read(casesListProvider.notifier)
          .selectFilter(CaseFilter.assigned);

      expect(
        container.read(casesListProvider).value!.visible.map((c) => c.id),
        ['b', 'c'],
      );
    });

    test('keeps every case in items so the total stays right', () async {
      stubCases(Ok(_allCases));

      final container = makeContainer();
      await container.read(casesListProvider.future);
      container
          .read(casesListProvider.notifier)
          .selectFilter(CaseFilter.closed);

      final state = container.read(casesListProvider).value!;
      expect(state.visible, hasLength(1));
      expect(state.items, hasLength(5));
    });

    test('ignores a re-select of the current tab', () async {
      stubCases(Ok(_allCases));

      final container = makeContainer();
      await container.read(casesListProvider.future);
      final before = container.read(casesListProvider);

      container.read(casesListProvider.notifier).selectFilter(CaseFilter.all);

      expect(identical(container.read(casesListProvider), before), isTrue);
    });
  });

  group('refresh', () {
    test('re-reads the repository', () async {
      stubCases(Ok(_allCases));

      final container = makeContainer();
      await container.read(casesListProvider.future);
      await container.read(casesListProvider.notifier).refresh();

      verify(repository.fetchCases).called(2);
    });

    test('holds the selected tab across a reload', () async {
      stubCases(Ok(_allCases));

      final container = makeContainer();
      await container.read(casesListProvider.future);
      final notifier = container.read(casesListProvider.notifier)
        ..selectFilter(CaseFilter.closed);

      await notifier.refresh();

      expect(container.read(casesListProvider).value!.filter, CaseFilter.closed);
    });

    test('surfaces a failure that arrives on reload', () async {
      stubCases(Ok(_allCases));

      final container = makeContainer();
      await container.read(casesListProvider.future);

      stubCases(const Err(_serverFailure));
      await container.read(casesListProvider.notifier).refresh();

      expect(container.read(casesListProvider).failure, _serverFailure);
    });
  });
}
