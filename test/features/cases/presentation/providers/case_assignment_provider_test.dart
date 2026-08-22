import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:propertyintelmobileapp/core/utils/error/app_failure.dart';
import 'package:propertyintelmobileapp/core/utils/error/async_value_x.dart';
import 'package:propertyintelmobileapp/core/utils/error/failure_type.dart';
import 'package:propertyintelmobileapp/core/utils/result.dart';
import 'package:propertyintelmobileapp/features/cases/domain/entities/case.dart';
import 'package:propertyintelmobileapp/features/cases/domain/entities/case_status.dart';
import 'package:propertyintelmobileapp/features/cases/domain/repositories/cases_repository.dart';
import 'package:propertyintelmobileapp/features/cases/presentation/providers/case_assignment_provider.dart';
import 'package:propertyintelmobileapp/features/cases/presentation/providers/case_detail_provider.dart';
import 'package:propertyintelmobileapp/features/cases/presentation/providers/cases_list_provider.dart';
import 'package:propertyintelmobileapp/features/cases/presentation/providers/cases_providers.dart';

import '../../case_fixtures.dart';

class MockCasesRepository extends Mock implements CasesRepository {}

const _ada = ada;

final _unassigned = buildCase(id: 'case-101');

final _assigned = buildCase(
  id: 'case-101',
  status: CaseStatus.assigned,
  assignee: _ada,
);

const _conflictFailure = AppFailure(
  type: FailureType.conflict,
  message: 'That case is already assigned to someone else.',
  statusCode: 409,
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

  void stubAssign(Result<Case> result) {
    when(
      () => repository.assignCase(
        caseId: any(named: 'caseId'),
        assigneeId: any(named: 'assigneeId'),
      ),
    ).thenAnswer((_) async => result);
  }

  group('assign', () {
    test('reports success and sends the ids through', () async {
      stubAssign(Ok(_assigned));
      when(repository.fetchCases).thenAnswer((_) async => Ok([_assigned]));

      final container = makeContainer();
      final assigned = await container
          .read(caseAssignmentProvider.notifier)
          .assign(caseId: 'case-101', assigneeId: 'stf-1');

      expect(assigned, isTrue);
      expect(container.read(caseAssignmentProvider).hasError, isFalse);
      verify(
        () => repository.assignCase(caseId: 'case-101', assigneeId: 'stf-1'),
      ).called(1);
    });

    test('patches the list row from the returned case, without re-reading',
        () async {
      stubAssign(Ok(_assigned));
      when(repository.fetchCases).thenAnswer((_) async => Ok([_unassigned]));

      final container = makeContainer();
      await container.read(casesListProvider.future);

      await container
          .read(caseAssignmentProvider.notifier)
          .assign(caseId: 'case-101', assigneeId: 'stf-1');

      final items = container.read(casesListProvider).value!.items;
      expect(items.single.assignee, _ada);
      expect(items.single.status, CaseStatus.assigned);
      // Only the initial build read the list: the row was corrected from the
      // write's own response.
      verify(repository.fetchCases).called(1);
    });

    test('leaves the other rows alone', () async {
      final other = buildCase(
        id: 'case-102',
        applicantName: 'Musa Ibrahim',
        propertyType: 'land',
      );
      stubAssign(Ok(_assigned));
      when(
        repository.fetchCases,
      ).thenAnswer((_) async => Ok([_unassigned, other]));

      final container = makeContainer();
      await container.read(casesListProvider.future);

      await container
          .read(caseAssignmentProvider.notifier)
          .assign(caseId: 'case-101', assigneeId: 'stf-1');

      final items = container.read(casesListProvider).value!.items;
      expect(items.first, _assigned);
      expect(items.last, other);
    });

    test('patches the detail screen so it cannot contradict itself', () async {
      stubAssign(Ok(_assigned));
      when(
        () => repository.fetchCase('case-101'),
      ).thenAnswer((_) async => Ok(_unassigned));

      final container = makeContainer();
      await container.read(caseDetailProvider('case-101').future);

      await container
          .read(caseAssignmentProvider.notifier)
          .assign(caseId: 'case-101', assigneeId: 'stf-1');

      expect(container.read(caseDetailProvider('case-101')).value, _assigned);
      // The confirmation and the screen agree immediately — no second read.
      verify(() => repository.fetchCase('case-101')).called(1);
    });

    test('reports failure and holds an AppFailure, never a raw error', () async {
      stubAssign(const Err(_conflictFailure));

      final container = makeContainer();
      final assigned = await container
          .read(caseAssignmentProvider.notifier)
          .assign(caseId: 'case-101', assigneeId: 'stf-1');

      expect(assigned, isFalse);
      expect(container.read(caseAssignmentProvider).failure, _conflictFailure);
    });

    test('leaves the list alone when the write failed', () async {
      when(repository.fetchCases).thenAnswer((_) async => Ok([_unassigned]));
      stubAssign(const Err(_conflictFailure));

      final container = makeContainer();
      await container.read(casesListProvider.future);

      await container
          .read(caseAssignmentProvider.notifier)
          .assign(caseId: 'case-101', assigneeId: 'stf-1');

      verify(repository.fetchCases).called(1);
      expect(
        container.read(casesListProvider).value!.items.single.assignee,
        isNull,
      );
    });

    test('does nothing to a list that has not been loaded', () async {
      stubAssign(Ok(_assigned));
      when(repository.fetchCases).thenAnswer((_) async => Ok([_unassigned]));

      final container = makeContainer();
      final assigned = await container
          .read(caseAssignmentProvider.notifier)
          .assign(caseId: 'case-101', assigneeId: 'stf-1');

      // The patch is skipped rather than throwing; the list loads correctly
      // when the user reaches it.
      expect(assigned, isTrue);
      expect(
        (await container.read(casesListProvider.future)).items,
        [_unassigned],
      );
    });

    test('clears an earlier failure on a later success', () async {
      stubAssign(const Err(_conflictFailure));
      when(repository.fetchCases).thenAnswer((_) async => Ok([_assigned]));

      final container = makeContainer();
      final notifier = container.read(caseAssignmentProvider.notifier);
      await notifier.assign(caseId: 'case-101', assigneeId: 'stf-1');
      expect(container.read(caseAssignmentProvider).hasError, isTrue);

      stubAssign(Ok(_assigned));
      await notifier.assign(caseId: 'case-101', assigneeId: 'stf-2');

      expect(container.read(caseAssignmentProvider).hasError, isFalse);
      expect(container.read(caseAssignmentProvider).failure, isNull);
    });
  });
}
