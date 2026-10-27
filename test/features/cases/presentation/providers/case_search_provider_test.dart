import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:propertyintelmobileapp/core/utils/error/app_failure.dart';
import 'package:propertyintelmobileapp/core/utils/error/async_value_x.dart';
import 'package:propertyintelmobileapp/core/utils/error/failure_type.dart';
import 'package:propertyintelmobileapp/core/utils/result.dart';
import 'package:propertyintelmobileapp/features/cases/domain/entities/case.dart';
import 'package:propertyintelmobileapp/features/cases/domain/repositories/cases_repository.dart';
import 'package:propertyintelmobileapp/features/cases/presentation/providers/case_search_provider.dart';
import 'package:propertyintelmobileapp/features/cases/presentation/providers/cases_providers.dart';

import '../../case_fixtures.dart';

class MockCasesRepository extends Mock implements CasesRepository {}

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

  /// Keeps the search alive and lets it settle, through a listener: awaiting
  /// `.future` on a provider whose build throws can hang (LESSONS).
  Future<AsyncValue<List<Case>?>> settle(ProviderContainer container) async {
    final sub = container.listen(caseSearchProvider, (_, _) {});
    addTearDown(sub.close);
    for (var i = 0; i < 20 && sub.read().isLoading; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    return sub.read();
  }

  test('an empty or one-letter bar is not a search', () async {
    final container = makeContainer();
    container.read(caseSearchQueryProvider.notifier).change('P');

    final value = await settle(container);

    expect(value.value, isNull);
    verifyNever(() => repository.searchCases(any()));
  });

  test('two or more characters search, trimmed', () async {
    final found = [buildCase(id: 'case-7')];
    when(
      () => repository.searchCases('PI-2RW'),
    ).thenAnswer((_) async => Ok(found));
    final container = makeContainer();
    container.read(caseSearchQueryProvider.notifier).change(' PI-2RW ');

    final value = await settle(container);

    expect(value.value, found);
  });

  test('a failure surfaces as an AppFailure, and is not retried', () async {
    const failure = AppFailure(type: FailureType.server, message: 'Down.');
    when(
      () => repository.searchCases(any()),
    ).thenAnswer((_) async => const Err(failure));
    final container = makeContainer();
    container.read(caseSearchQueryProvider.notifier).change('Zz');

    final value = await settle(container);
    await Future<void>.delayed(const Duration(milliseconds: 300));

    expect(value.failure, failure);
    verify(() => repository.searchCases('Zz')).called(1);
  });
}
