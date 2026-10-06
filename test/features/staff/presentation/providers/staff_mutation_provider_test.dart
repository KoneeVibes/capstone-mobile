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
import 'package:propertyintelmobileapp/features/staff/domain/entities/staff_page.dart';
import 'package:propertyintelmobileapp/features/staff/domain/entities/staff_status.dart';
import 'package:propertyintelmobileapp/features/staff/domain/repositories/staff_repository.dart';
import 'package:propertyintelmobileapp/features/staff/presentation/providers/staff_list_provider.dart';
import 'package:propertyintelmobileapp/features/staff/presentation/providers/staff_mutation_provider.dart';
import 'package:propertyintelmobileapp/features/staff/presentation/providers/staff_providers.dart';

class MockStaffRepository extends Mock implements StaffRepository {}

const _draft = StaffDraft(
  firstName: 'Ekong',
  lastName: 'Silas',
  email: 'ekong@slp.africa',
  phone: '08034112290',
  role: StaffRole.admin,
);

const _staff = Staff(
  id: 'staff-1',
  firstName: 'Ekong',
  lastName: 'Silas',
  email: 'ekong@slp.africa',
  role: StaffRole.admin,
  status: StaffStatus.active,
);

const _conflict = AppFailure(
  type: FailureType.conflict,
  message: 'A staff member with this email already exists.',
  statusCode: 409,
);

void main() {
  late MockStaffRepository repository;

  setUpAll(() => registerFallbackValue(_draft));

  setUp(() => repository = MockStaffRepository());

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [staffRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('createStaff', () {
    test('returns true and settles to data on success', () async {
      when(
        () => repository.createStaff(any()),
      ).thenAnswer((_) async => const Ok<void>(null));

      final container = makeContainer();
      final created = await container
          .read(staffMutationProvider.notifier)
          .createStaff(_draft);

      expect(created, isTrue);
      expect(container.read(staffMutationProvider).hasError, isFalse);
    });

    test('returns false and exposes an AppFailure on conflict', () async {
      when(
        () => repository.createStaff(any()),
      ).thenAnswer((_) async => const Err(_conflict));

      final container = makeContainer();
      final created = await container
          .read(staffMutationProvider.notifier)
          .createStaff(_draft);

      expect(created, isFalse);

      final state = container.read(staffMutationProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<AppFailure>());
      expect(state.failure, _conflict);
      expect(state.failure!.message, isNot(contains('Exception')));
    });

    test('invalidates the list so the new record shows up', () async {
      when(() => repository.fetchStaff(
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
          )).thenAnswer((_) async => const Ok(StaffPage.empty()));
      when(
        () => repository.createStaff(any()),
      ).thenAnswer((_) async => const Ok<void>(null));

      final container = makeContainer();
      await container.read(staffListProvider.future);

      await container.read(staffMutationProvider.notifier).createStaff(_draft);
      await container.read(staffListProvider.future);

      verify(() => repository.fetchStaff(
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
          )).called(2);
    });

    test('does not invalidate the list when the call failed', () async {
      when(() => repository.fetchStaff(
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
          )).thenAnswer((_) async => const Ok(StaffPage.empty()));
      when(
        () => repository.createStaff(any()),
      ).thenAnswer((_) async => const Err(_conflict));

      final container = makeContainer();
      await container.read(staffListProvider.future);

      await container.read(staffMutationProvider.notifier).createStaff(_draft);
      await container.read(staffListProvider.future);

      verify(() => repository.fetchStaff(
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
          )).called(1);
    });
  });

  group('updateStaff', () {
    test('returns true on success', () async {
      when(
        () => repository.updateStaff(id: 'staff-1', draft: any(named: 'draft')),
      ).thenAnswer((_) async => const Ok(_staff));

      final container = makeContainer();
      final saved = await container
          .read(staffMutationProvider.notifier)
          .updateStaff(id: 'staff-1', draft: _draft);

      expect(saved, isTrue);
    });

    test('returns false and exposes the failure', () async {
      const notFound = AppFailure(
        type: FailureType.notFound,
        message: "We couldn't find what you were looking for.",
        statusCode: 404,
      );
      when(
        () => repository.updateStaff(id: 'gone', draft: any(named: 'draft')),
      ).thenAnswer((_) async => const Err(notFound));

      final container = makeContainer();
      final saved = await container
          .read(staffMutationProvider.notifier)
          .updateStaff(id: 'gone', draft: _draft);

      expect(saved, isFalse);
      expect(container.read(staffMutationProvider).failure, notFound);
    });
  });

  group('removeStaff', () {
    test('returns true on success', () async {
      when(
        () => repository.deactivateStaff('staff-1'),
      ).thenAnswer((_) async => const Ok(_staff));

      final container = makeContainer();
      final removed = await container
          .read(staffMutationProvider.notifier)
          .removeStaff('staff-1');

      expect(removed, isTrue);
    });

    test('returns false and exposes the failure', () async {
      const serverFailure = AppFailure(
        type: FailureType.server,
        message: 'Something went wrong on our end. Please try again shortly.',
        statusCode: 500,
      );
      when(
        () => repository.deactivateStaff('staff-1'),
      ).thenAnswer((_) async => const Err(serverFailure));

      final container = makeContainer();
      final removed = await container
          .read(staffMutationProvider.notifier)
          .removeStaff('staff-1');

      expect(removed, isFalse);
      expect(container.read(staffMutationProvider).failure, serverFailure);
    });
  });
}
