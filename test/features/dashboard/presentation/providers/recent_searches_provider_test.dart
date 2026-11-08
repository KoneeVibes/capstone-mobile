import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:propertyintelmobileapp/core/utils/result.dart';
import 'package:propertyintelmobileapp/features/dashboard/domain/entities/recent_search.dart';
import 'package:propertyintelmobileapp/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:propertyintelmobileapp/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:propertyintelmobileapp/features/dashboard/presentation/providers/recent_searches_provider.dart';

import '../../../../core/navigation/session_fixtures.dart';

class MockDashboardRepository extends Mock implements DashboardRepository {}

const _searches = [RecentSearch(id: 'h-1', trackingId: 'PI-8APCC9W3')];

void main() {
  late MockDashboardRepository repository;

  setUp(() {
    repository = MockDashboardRepository();
    when(
      () => repository.fetchRecentSearches(limit: any(named: 'limit')),
    ).thenAnswer((_) async => const Ok(_searches));
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
      ..listen(recentSearchesProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);

    expect(container.read(recentSearchesProvider).isLoading, isTrue);
    verifyNever(
      () => repository.fetchRecentSearches(limit: any(named: 'limit')),
    );
  });

  test('reads the newest searches once signed in', () async {
    final container = makeContainer();

    expect(await container.read(recentSearchesProvider.future), _searches);
    verify(
      () => repository.fetchRecentSearches(limit: recentSearchesLimit),
    ).called(1);
  });
}
