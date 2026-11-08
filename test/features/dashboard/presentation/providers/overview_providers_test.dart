import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:propertyintelmobileapp/core/navigation/app_session.dart';
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

  test("the next user never sees the last one's counts", () async {
    final user = NotifierProvider<_Session, SessionUser?>(_Session.new);
    final container = ProviderContainer(
      overrides: [
        dashboardRepositoryProvider.overrideWithValue(repository),
        sessionProvider.overrideWith((ref) => ref.watch(user)),
      ],
    );
    addTearDown(container.dispose);

    var home = container.listen(caseOverviewProvider, (_, _) {});
    expect(await container.read(caseOverviewProvider.future), _client);

    container.read(user.notifier).set(null);
    home.close();
    await container.pump();

    final pending = Completer<Result<CaseOverview>>();
    when(
      () => repository.fetchClientOverview(),
    ).thenAnswer((_) => pending.future);
    container
        .read(user.notifier)
        .set(const SessionUser(id: 'user-2', role: AppRole.client));
    home = container.listen(caseOverviewProvider, (_, _) {});

    expect(container.read(caseOverviewProvider).value, isNull);
    pending.complete(
      const Ok(
        CaseOverview(total: 0, reportsReady: 0, inProgress: 0, needsInput: 0),
      ),
    );
    expect((await container.read(caseOverviewProvider.future)).total, 0);
    home.close();
  });
}

class _Session extends Notifier<SessionUser?> {
  @override
  SessionUser? build() => const SessionUser(id: 'user-1', role: AppRole.client);

  void set(SessionUser? user) => state = user;
}
