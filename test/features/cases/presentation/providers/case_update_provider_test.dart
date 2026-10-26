import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:propertyintelmobileapp/core/utils/error/app_failure.dart';
import 'package:propertyintelmobileapp/core/utils/error/async_value_x.dart';
import 'package:propertyintelmobileapp/core/utils/error/failure_type.dart';
import 'package:propertyintelmobileapp/core/utils/media_picker.dart';
import 'package:propertyintelmobileapp/core/utils/result.dart';
import 'package:propertyintelmobileapp/features/cases/domain/entities/case.dart';
import 'package:propertyintelmobileapp/features/cases/domain/entities/case_status.dart';
import 'package:propertyintelmobileapp/features/cases/domain/repositories/cases_repository.dart';
import 'package:propertyintelmobileapp/features/cases/presentation/providers/case_detail_provider.dart';
import 'package:propertyintelmobileapp/features/cases/presentation/providers/case_update_provider.dart';
import 'package:propertyintelmobileapp/features/cases/presentation/providers/cases_list_provider.dart';
import 'package:propertyintelmobileapp/features/cases/presentation/providers/cases_providers.dart';

import '../../case_fixtures.dart';

class MockCasesRepository extends Mock implements CasesRepository {}

final _assigned = buildCase(
  id: 'case-101',
  status: CaseStatus.assigned,
  assignee: ada,
);

final _accepted = buildCase(
  id: 'case-101',
  status: CaseStatus.accepted,
  assignee: ada,
);

const _report = PickedMedia(
  path: '/tmp/report.pdf',
  fileName: 'report.pdf',
  sizeBytes: 1024,
  extension: 'pdf',
);

const _refused = AppFailure(
  type: FailureType.conflict,
  message: 'This case cannot be suspended.',
  statusCode: 409,
);

void main() {
  late MockCasesRepository repository;

  setUpAll(() {
    registerFallbackValue(CaseStatus.unknown);
    registerFallbackValue(<PickedMedia>[]);
  });

  setUp(() => repository = MockCasesRepository());

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [casesRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    return container;
  }

  void stubStatus(Result<Case> result) {
    when(
      () => repository.updateStatus(
        caseId: any(named: 'caseId'),
        status: any(named: 'status'),
      ),
    ).thenAnswer((_) async => result);
  }

  void stubSuspend(Result<Case> result) {
    when(
      () => repository.suspendCase(caseId: any(named: 'caseId')),
    ).thenAnswer((_) async => result);
  }

  test('accept and close each send their own status', () async {
    stubStatus(Ok(_accepted));
    final notifier = makeContainer().read(caseUpdateProvider.notifier);

    await notifier.accept('case-101');
    await notifier.close('case-101');

    for (final status in [CaseStatus.accepted, CaseStatus.closed]) {
      verify(
        () => repository.updateStatus(caseId: 'case-101', status: status),
      ).called(1);
    }
  });

  test('suspend is its own write, not a status update', () async {
    stubSuspend(Ok(buildCase(id: 'case-101', status: CaseStatus.suspended)));

    final suspended = await makeContainer()
        .read(caseUpdateProvider.notifier)
        .suspend('case-101');

    expect(suspended, isTrue);
    verify(() => repository.suspendCase(caseId: 'case-101')).called(1);
    verifyNever(
      () => repository.updateStatus(
        caseId: any(named: 'caseId'),
        status: any(named: 'status'),
      ),
    );
  });

  test('puts the returned case into the list, without re-reading', () async {
    stubStatus(Ok(_accepted));
    when(repository.fetchCases).thenAnswer((_) async => Ok([_assigned]));

    final container = makeContainer();
    await container.read(casesListProvider.future);

    final accepted = await container
        .read(caseUpdateProvider.notifier)
        .accept('case-101');

    expect(accepted, isTrue);
    final items = container.read(casesListProvider).value!.items;
    expect(items.single.status, CaseStatus.accepted);
    verify(repository.fetchCases).called(1);
  });

  test('puts the returned case into an open detail screen', () async {
    final reviewed = buildCase(
      id: 'case-101',
      status: CaseStatus.underReview,
      assignee: ada,
      reports: const ['https://x/report.pdf'],
    );
    when(
      () => repository.submitReport(
        caseId: any(named: 'caseId'),
        files: any(named: 'files'),
      ),
    ).thenAnswer((_) async => Ok(reviewed));
    when(
      () => repository.fetchCase('case-101'),
    ).thenAnswer((_) async => Ok(_accepted));

    final container = makeContainer();
    await container.read(caseDetailProvider('case-101').future);

    await container.read(caseUpdateProvider.notifier).submitReport(
      'case-101',
      const [_report],
    );

    expect(container.read(caseDetailProvider('case-101')).value, reviewed);
    verify(
      () => repository.submitReport(caseId: 'case-101', files: const [_report]),
    ).called(1);
    verify(() => repository.fetchCase('case-101')).called(1);
  });

  test('starts no read for a screen nobody has open', () async {
    stubStatus(Ok(_accepted));

    await makeContainer().read(caseUpdateProvider.notifier).accept('case-101');

    verifyNever(repository.fetchCases);
    verifyNever(() => repository.fetchCase(any()));
  });

  test('a refusal returns false and holds the AppFailure', () async {
    stubSuspend(const Err(_refused));

    final container = makeContainer();
    final suspended = await container
        .read(caseUpdateProvider.notifier)
        .suspend('case-101');

    expect(suspended, isFalse);
    expect(container.read(caseUpdateProvider).failure, _refused);
  });
}
