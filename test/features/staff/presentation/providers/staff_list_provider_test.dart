import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:propertyintelmobileapp/core/network/api_response.dart';
import 'package:propertyintelmobileapp/core/session/staff_role.dart';
import 'package:propertyintelmobileapp/core/utils/error/app_failure.dart';
import 'package:propertyintelmobileapp/core/utils/error/async_value_x.dart';
import 'package:propertyintelmobileapp/core/utils/error/failure_type.dart';
import 'package:propertyintelmobileapp/core/utils/result.dart';
import 'package:propertyintelmobileapp/features/staff/domain/entities/staff.dart';
import 'package:propertyintelmobileapp/features/staff/domain/entities/staff_page.dart';
import 'package:propertyintelmobileapp/features/staff/domain/entities/staff_status.dart';
import 'package:propertyintelmobileapp/features/staff/domain/repositories/staff_repository.dart';
import 'package:propertyintelmobileapp/features/staff/presentation/providers/staff_list_provider.dart';
import 'package:propertyintelmobileapp/features/staff/presentation/providers/staff_providers.dart';

class MockStaffRepository extends Mock implements StaffRepository {}

Staff _staff(String id) => Staff(
  id: id,
  firstName: 'Staff',
  lastName: id,
  email: '$id@example.com',
  role: StaffRole.regular,
  status: StaffStatus.active,
);

StaffPage _page(List<String> ids, {required int page, required int totalPages}) =>
    StaffPage(
      items: ids.map(_staff).toList(),
      meta: PageMeta(
        page: page,
        perPage: 20,
        total: totalPages * 20,
        totalPages: totalPages,
      ),
    );

const _serverFailure = AppFailure(
  type: FailureType.server,
  message: 'Something went wrong on our end. Please try again shortly.',
  statusCode: 500,
);

void main() {
  late MockStaffRepository repository;

  setUp(() => repository = MockStaffRepository());

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [staffRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    return container;
  }

  void stubPage(int page, Result<StaffPage> result) {
    when(
      () => repository.fetchStaff(page: page, perPage: any(named: 'perPage')),
    ).thenAnswer((_) async => result);
  }

  group('initial load', () {
    test('exposes the first page', () async {
      stubPage(1, Ok(_page(['a', 'b'], page: 1, totalPages: 3)));

      final container = makeContainer();
      final state = await container.read(staffListProvider.future);

      expect(state.items.map((s) => s.id), ['a', 'b']);
      expect(state.hasMore, isTrue);
      expect(state.isEmpty, isFalse);
      expect(state.loadMoreFailure, isNull);
    });

    test('reports an empty list without erroring', () async {
      stubPage(1, const Ok(StaffPage.empty()));

      final container = makeContainer();
      final state = await container.read(staffListProvider.future);

      expect(state.isEmpty, isTrue);
      expect(state.hasMore, isFalse);
    });

    test('surfaces a failure as an AppFailure, not a raw exception', () async {
      stubPage(1, const Err(_serverFailure));

      final container = makeContainer();

      // Observed through a listener rather than `.future`: a build that throws
      // leaves that future pending, and the errored state is what the UI
      // actually reads.
      container.listen(staffListProvider, (_, _) {}, fireImmediately: true);
      await pumpEventQueue();

      final async = container.read(staffListProvider);
      expect(async.hasError, isTrue);
      expect(async.error, isA<AppFailure>());
      expect(async.failure, _serverFailure);
      expect(async.failure!.message, isNot(contains('Exception')));
    });
  });

  group('loadMore', () {
    test('appends the next page and advances the meta', () async {
      stubPage(1, Ok(_page(['a', 'b'], page: 1, totalPages: 2)));
      stubPage(2, Ok(_page(['c'], page: 2, totalPages: 2)));

      final container = makeContainer();
      await container.read(staffListProvider.future);

      await container.read(staffListProvider.notifier).loadMore();

      final state = container.read(staffListProvider).requireValue;
      expect(state.items.map((s) => s.id), ['a', 'b', 'c']);
      expect(state.meta?.page, 2);
      expect(state.hasMore, isFalse);
      expect(state.isLoadingMore, isFalse);
    });

    test('does nothing once the last page is loaded', () async {
      stubPage(1, Ok(_page(['a'], page: 1, totalPages: 1)));

      final container = makeContainer();
      await container.read(staffListProvider.future);

      await container.read(staffListProvider.notifier).loadMore();

      verifyNever(
        () => repository.fetchStaff(page: 2, perPage: any(named: 'perPage')),
      );
    });

    test('keeps the loaded rows when the next page fails', () async {
      stubPage(1, Ok(_page(['a', 'b'], page: 1, totalPages: 3)));
      stubPage(2, const Err(_serverFailure));

      final container = makeContainer();
      await container.read(staffListProvider.future);

      await container.read(staffListProvider.notifier).loadMore();

      final async = container.read(staffListProvider);
      expect(async.hasError, isFalse, reason: 'the list must stay usable');

      final state = async.requireValue;
      expect(state.items.map((s) => s.id), ['a', 'b']);
      expect(state.loadMoreFailure, _serverFailure);
      expect(state.isLoadingMore, isFalse);
      expect(state.hasMore, isTrue, reason: 'retry must remain possible');
    });

    test('clears a previous load-more failure on a successful retry', () async {
      stubPage(1, Ok(_page(['a'], page: 1, totalPages: 2)));
      stubPage(2, const Err(_serverFailure));

      final container = makeContainer();
      await container.read(staffListProvider.future);
      await container.read(staffListProvider.notifier).loadMore();

      expect(
        container.read(staffListProvider).requireValue.loadMoreFailure,
        isNotNull,
      );

      stubPage(2, Ok(_page(['b'], page: 2, totalPages: 2)));
      await container.read(staffListProvider.notifier).loadMore();

      final state = container.read(staffListProvider).requireValue;
      expect(state.loadMoreFailure, isNull);
      expect(state.items.map((s) => s.id), ['a', 'b']);
    });

    test('ignores overlapping calls while a page is in flight', () async {
      stubPage(1, Ok(_page(['a'], page: 1, totalPages: 5)));

      final container = makeContainer();
      await container.read(staffListProvider.future);

      // Scrolling fires this on every frame; only one request may go out.
      when(
        () => repository.fetchStaff(page: 2, perPage: any(named: 'perPage')),
      ).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return Ok(_page(['b'], page: 2, totalPages: 5));
      });

      final notifier = container.read(staffListProvider.notifier);
      await Future.wait([
        notifier.loadMore(),
        notifier.loadMore(),
        notifier.loadMore(),
      ]);

      verify(
        () => repository.fetchStaff(page: 2, perPage: any(named: 'perPage')),
      ).called(1);
    });
  });

  group('refresh', () {
    test('reloads from page one', () async {
      stubPage(1, Ok(_page(['a'], page: 1, totalPages: 2)));
      stubPage(2, Ok(_page(['b'], page: 2, totalPages: 2)));

      final container = makeContainer();
      await container.read(staffListProvider.future);
      await container.read(staffListProvider.notifier).loadMore();

      stubPage(1, Ok(_page(['z'], page: 1, totalPages: 1)));
      await container.read(staffListProvider.notifier).refresh();

      final state = container.read(staffListProvider).requireValue;
      expect(state.items.map((s) => s.id), ['z']);
      expect(state.hasMore, isFalse);
    });

    test('exposes a refresh failure as an AppFailure', () async {
      stubPage(1, Ok(_page(['a'], page: 1, totalPages: 1)));

      final container = makeContainer();
      await container.read(staffListProvider.future);

      stubPage(1, const Err(_serverFailure));
      await container.read(staffListProvider.notifier).refresh();

      expect(container.read(staffListProvider).failure, _serverFailure);
    });
  });
}
