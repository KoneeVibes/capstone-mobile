import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:propertyintelmobileapp/core/session/cases_changed.dart';
import 'package:propertyintelmobileapp/core/utils/result.dart';
import 'package:propertyintelmobileapp/features/dashboard/domain/entities/case_overview.dart';
import 'package:propertyintelmobileapp/features/dashboard/domain/entities/queue_overview.dart';
import 'package:propertyintelmobileapp/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:propertyintelmobileapp/features/dashboard/presentation/providers/case_overview_provider.dart';
import 'package:propertyintelmobileapp/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:propertyintelmobileapp/features/dashboard/presentation/providers/queue_overview_provider.dart';

import '../../../../core/navigation/session_fixtures.dart';

class MockDashboardRepository extends Mock implements DashboardRepository {}

const _client = CaseOverview(
  total: 7,
  reportsReady: 6,
  inProgress: 1,
  needsInput: 0,
);
const _staff = QueueOverview(inQueue: 3, assignedThisWeek: 8);

void main() {
  late MockDashboardRepository repository;

  setUp(() {
    repository = MockDashboardRepository();
    when(
      () => repository.fetchClientOverview(),
    ).thenAnswer((_) async => const Ok(_client));
    when(
      () => repository.fetchStaffOverview(),
    ).thenAnswer((_) async => const Ok(_staff));
  });

  ProviderContainer makeContainer({bool isSignedIn = true}) {
    final container = ProviderContainer(
      overrides: [
        dashboardRepositoryProvider.overrideWithValue(repository),
        if (isSignedIn) signedIn,
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('fetches nothing while signed out', () async {
    final container = makeContainer(isSignedIn: false)
      ..listen(caseOverviewProvider, (_, _) {})
      ..listen(queueOverviewProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);

    expect(container.read(caseOverviewProvider).isLoading, isTrue);
    verifyNever(() => repository.fetchClientOverview());
    verifyNever(() => repository.fetchStaffOverview());
  });

  test('reads each role\'s counts once signed in', () async {
    final container = makeContainer();

    expect(await container.read(caseOverviewProvider.future), _client);
    expect(await container.read(queueOverviewProvider.future), _staff);
  });

  test('recounts when the cases change', () async {
    final container = makeContainer()..listen(queueOverviewProvider, (_, _) {});
    await container.read(queueOverviewProvider.future);

    container.read(casesChangedProvider.notifier).bump();
    await container.read(queueOverviewProvider.future);

    verify(() => repository.fetchStaffOverview()).called(2);
  });
}
