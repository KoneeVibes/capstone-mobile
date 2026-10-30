import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:propertyintelmobileapp/core/utils/error/app_failure.dart';
import 'package:propertyintelmobileapp/core/utils/error/async_value_x.dart';
import 'package:propertyintelmobileapp/core/utils/error/failure_type.dart';
import 'package:propertyintelmobileapp/core/utils/media_picker.dart';
import 'package:propertyintelmobileapp/core/utils/result.dart';
import 'package:propertyintelmobileapp/features/cases/domain/entities/case_dispute.dart';
import 'package:propertyintelmobileapp/features/cases/domain/repositories/disputes_repository.dart';
import 'package:propertyintelmobileapp/features/cases/presentation/providers/case_disputes_provider.dart';
import 'package:propertyintelmobileapp/features/cases/presentation/providers/cases_providers.dart';
import 'package:propertyintelmobileapp/features/cases/presentation/providers/dispute_update_provider.dart';

class MockDisputesRepository extends Mock implements DisputesRepository {}

const _open = CaseDispute(
  id: 'dispute-1',
  caseId: 'case-1',
  title: 'Wrong plot',
  description: 'The survey covers the next plot.',
  status: DisputeStatus.open,
);

const _rejected = CaseDispute(
  id: 'dispute-1',
  caseId: 'case-1',
  title: 'Wrong plot',
  description: 'The survey covers the next plot.',
  status: DisputeStatus.rejected,
  rejectionNote: 'The report stands.',
);

const _refused = AppFailure(
  type: FailureType.notFound,
  message: 'The case was not found, is not closed, or is not yours.',
  statusCode: 404,
);

void main() {
  late MockDisputesRepository repository;

  setUpAll(() => registerFallbackValue(<PickedMedia>[]));

  setUp(() => repository = MockDisputesRepository());

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [disputesRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    return container;
  }

  void stubList(List<CaseDispute> disputes) {
    when(
      () => repository.fetchDisputes(any()),
    ).thenAnswer((_) async => Ok(disputes));
  }

  void stubRaise(Result<void> result) {
    when(
      () => repository.raiseDispute(
        caseId: any(named: 'caseId'),
        title: any(named: 'title'),
        description: any(named: 'description'),
        attachments: any(named: 'attachments'),
      ),
    ).thenAnswer((_) async => result);
  }

  test('loads the case\'s disputes', () async {
    stubList([_open]);
    final container = makeContainer();

    expect(await container.read(caseDisputesProvider('case-1').future), [
      _open,
    ]);
    verify(() => repository.fetchDisputes('case-1')).called(1);
  });

  test('raising re-reads the list, since the API returns no record', () async {
    stubList(const []);
    stubRaise(const Ok(null));
    final container = makeContainer();
    await container.read(caseDisputesProvider('case-1').future);

    stubList([_open]);
    final raised = await container
        .read(disputeUpdateProvider.notifier)
        .raise(caseId: 'case-1', title: 'Wrong plot', description: 'Next.');

    expect(raised, isTrue);
    expect(await container.read(caseDisputesProvider('case-1').future), [
      _open,
    ]);
  });

  test('a refused raise holds the failure and returns false', () async {
    stubRaise(const Err(_refused));
    final container = makeContainer();

    final raised = await container
        .read(disputeUpdateProvider.notifier)
        .raise(caseId: 'case-1', title: 'Wrong plot', description: 'Next.');

    expect(raised, isFalse);
    expect(container.read(disputeUpdateProvider).failure, _refused);
  });

  test('declining puts the returned dispute into the list', () async {
    stubList([_open]);
    when(
      () => repository.rejectDispute(
        disputeId: 'dispute-1',
        note: 'The report stands.',
      ),
    ).thenAnswer((_) async => const Ok(_rejected));
    final container = makeContainer();
    // Held open, as the case screen holds it.
    container.listen(caseDisputesProvider('case-1'), (_, _) {});
    await container.read(caseDisputesProvider('case-1').future);

    final declined = await container
        .read(disputeUpdateProvider.notifier)
        .decline(
          caseId: 'case-1',
          disputeId: 'dispute-1',
          note: 'The report stands.',
        );

    expect(declined, isTrue);
    expect(container.read(caseDisputesProvider('case-1')).value, [_rejected]);
    // Pushed in, not re-read.
    verify(() => repository.fetchDisputes('case-1')).called(1);
  });

  test('closing the case drops its disputes; the next open re-reads', () async {
    stubList([_open]);
    final container = makeContainer();
    final screen = container.listen(caseDisputesProvider('case-1'), (_, _) {});
    await container.read(caseDisputesProvider('case-1').future);

    screen.close();
    await container.pump();
    stubList([_rejected]);

    expect(await container.read(caseDisputesProvider('case-1').future), [
      _rejected,
    ]);
  });

  test('hasOpenDispute', () {
    expect(hasOpenDispute(const [_open]), isTrue);
    expect(hasOpenDispute(const [_rejected]), isFalse);
    expect(hasOpenDispute(const []), isFalse);
  });
}
