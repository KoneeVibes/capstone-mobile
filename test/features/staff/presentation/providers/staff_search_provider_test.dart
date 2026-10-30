import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:propertyintelmobileapp/core/session/staff_role.dart';
import 'package:propertyintelmobileapp/core/utils/error/app_failure.dart';
import 'package:propertyintelmobileapp/core/utils/error/async_value_x.dart';
import 'package:propertyintelmobileapp/core/utils/error/failure_type.dart';
import 'package:propertyintelmobileapp/core/utils/result.dart';
import 'package:propertyintelmobileapp/features/staff/domain/entities/staff.dart';
import 'package:propertyintelmobileapp/features/staff/domain/entities/staff_draft.dart';
import 'package:propertyintelmobileapp/features/staff/domain/entities/staff_status.dart';
import 'package:propertyintelmobileapp/features/staff/domain/repositories/staff_repository.dart';
import 'package:propertyintelmobileapp/features/staff/presentation/providers/staff_mutation_provider.dart';
import 'package:propertyintelmobileapp/features/staff/presentation/providers/staff_providers.dart';
import 'package:propertyintelmobileapp/features/staff/presentation/providers/staff_search_provider.dart';

import '../../../../core/navigation/session_fixtures.dart';

class MockStaffRepository extends Mock implements StaffRepository {}

const _ada = Staff(
  id: 'staff-1',
  firstName: 'Ada',
  lastName: 'Okafor',
  email: 'ada.okafor@example.com',
  role: StaffRole.manager,
  status: StaffStatus.active,
);

const _draft = StaffDraft(
  firstName: 'Ada',
  lastName: 'Okafor',
  email: 'ada.okafor@example.com',
  phone: '08034112290',
  role: StaffRole.manager,
);

void main() {
  late MockStaffRepository repository;

  setUpAll(() => registerFallbackValue(_draft));

  setUp(() => repository = MockStaffRepository());

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        staffRepositoryProvider.overrideWithValue(repository),
        signedIn,
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// Keeps the search alive and lets it settle, through a listener: awaiting
  /// `.future` on a provider whose build throws can hang (LESSONS).
  Future<AsyncValue<List<Staff>?>> settle(ProviderContainer container) async {
    final sub = container.listen(staffSearchProvider, (_, _) {});
    addTearDown(sub.close);
    for (var i = 0; i < 20 && sub.read().isLoading; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    return sub.read();
  }

  test('an empty or one-letter bar is not a search', () async {
    final container = makeContainer();
    container.read(staffSearchQueryProvider.notifier).change('A');

    final value = await settle(container);

    expect(value.value, isNull);
    verifyNever(() => repository.searchStaff(any()));
  });

  test('two or more characters search, trimmed', () async {
    when(
      () => repository.searchStaff('Ada'),
    ).thenAnswer((_) async => const Ok([_ada]));
    final container = makeContainer();
    container.read(staffSearchQueryProvider.notifier).change('  Ada ');

    final value = await settle(container);

    expect(value.value, [_ada]);
  });

  test('a failure surfaces as an AppFailure', () async {
    const failure = AppFailure(type: FailureType.server, message: 'Down.');
    when(
      () => repository.searchStaff(any()),
    ).thenAnswer((_) async => const Err(failure));
    final container = makeContainer();
    container.read(staffSearchQueryProvider.notifier).change('Ada');

    final value = await settle(container);

    expect(value.failure, failure);
  });

  test('an edit re-runs the search, so the row shows the change', () async {
    when(
      () => repository.searchStaff('Ada'),
    ).thenAnswer((_) async => const Ok([_ada]));
    when(
      () => repository.updateStaff(
        id: any(named: 'id'),
        draft: any(named: 'draft'),
      ),
    ).thenAnswer((_) async => const Ok(_ada));
    final container = makeContainer();
    container.read(staffSearchQueryProvider.notifier).change('Ada');
    await settle(container);

    await container
        .read(staffMutationProvider.notifier)
        .updateStaff(id: 'staff-1', draft: _draft);
    await settle(container);

    verify(() => repository.searchStaff('Ada')).called(2);
  });
}
