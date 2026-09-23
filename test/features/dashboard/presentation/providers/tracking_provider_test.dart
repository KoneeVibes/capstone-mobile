import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:propertyintelmobileapp/core/utils/error/app_failure.dart';
import 'package:propertyintelmobileapp/core/utils/error/async_value_x.dart';
import 'package:propertyintelmobileapp/core/utils/error/failure_type.dart';
import 'package:propertyintelmobileapp/core/utils/result.dart';
import 'package:propertyintelmobileapp/features/dashboard/domain/entities/recent_search.dart';
import 'package:propertyintelmobileapp/features/dashboard/domain/entities/tracked_case.dart';
import 'package:propertyintelmobileapp/features/dashboard/domain/entities/tracking_status.dart';
import 'package:propertyintelmobileapp/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:propertyintelmobileapp/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:propertyintelmobileapp/features/dashboard/presentation/providers/recent_searches_provider.dart';
import 'package:propertyintelmobileapp/features/dashboard/presentation/providers/tracking_provider.dart';

class MockDashboardRepository extends Mock implements DashboardRepository {}

const _tracked = TrackedCase(
  trackingId: 'PI-URF8T7C2',
  status: TrackingStatus.assigned,
  address: '5 Kayode Abraham',
);

const _notFound = AppFailure(
  type: FailureType.notFound,
  message: 'Case not found.',
  statusCode: 404,
);

void main() {
  late MockDashboardRepository repository;

  setUp(() => repository = MockDashboardRepository());

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [dashboardRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    return container;
  }

  void stubLookup(Result<TrackedCase> result) =>
      when(() => repository.trackCase(any())).thenAnswer((_) async => result);

  test('starts idle', () {
    expect(makeContainer().read(trackingProvider).value, isNull);
  });

  test('normalises the input, adding PI- to a bare code', () async {
    stubLookup(const Ok(_tracked));

    final container = makeContainer();
    await container.read(trackingProvider.notifier).track(' urf8t7c2 ');

    verify(() => repository.trackCase('PI-URF8T7C2')).called(1);
    expect(container.read(trackingProvider).value, _tracked);
  });

  test('sends nothing for an incomplete ID', () async {
    final container = makeContainer();
    await container.read(trackingProvider.notifier).track('PI-8K4M2Q');

    verifyNever(() => repository.trackCase(any()));
    expect(container.read(trackingProvider).value, isNull);
  });

  test('records a successful lookup in recent searches', () async {
    stubLookup(const Ok(_tracked));

    final container = makeContainer();
    await container.read(trackingProvider.notifier).track('PI-URF8T7C2');

    expect(container.read(recentSearchesProvider), [
      const RecentSearch(
        trackingId: 'PI-URF8T7C2',
        status: TrackingStatus.assigned,
        address: '5 Kayode Abraham',
      ),
    ]);
  });

  test('surfaces a failure without recording it', () async {
    stubLookup(const Err(_notFound));

    final container = makeContainer();
    await container.read(trackingProvider.notifier).track('PI-URF8T7C2');

    final state = container.read(trackingProvider);
    expect(state.failure?.message, 'Case not found.');
    expect(container.read(recentSearchesProvider), isEmpty);
  });

  test('clear drops a lookup that is still in flight', () async {
    final pending = Completer<Result<TrackedCase>>();
    when(() => repository.trackCase(any())).thenAnswer((_) => pending.future);

    final container = makeContainer();
    final notifier = container.read(trackingProvider.notifier);
    final lookup = notifier.track('PI-URF8T7C2');
    notifier.clear();
    pending.complete(const Ok(_tracked));
    await lookup;

    expect(container.read(trackingProvider).value, isNull);
    expect(container.read(recentSearchesProvider), isEmpty);
  });
}
