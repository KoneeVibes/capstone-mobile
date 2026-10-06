import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:propertyintelmobileapp/core/session/staff_role.dart';
import 'package:propertyintelmobileapp/core/utils/error/failure_type.dart';
import 'package:propertyintelmobileapp/features/staff/data/datasources/staff_remote_datasource.dart';
import 'package:propertyintelmobileapp/features/staff/data/repositories/staff_repository_impl.dart';
import 'package:propertyintelmobileapp/features/staff/domain/entities/staff.dart';
import 'package:propertyintelmobileapp/features/staff/domain/entities/staff_draft.dart';
import 'package:propertyintelmobileapp/features/staff/domain/entities/staff_page.dart';
import 'package:propertyintelmobileapp/features/staff/domain/entities/staff_status.dart';

class MockStaffRemoteDataSource extends Mock implements StaffRemoteDataSource {}

const _staff = Staff(
  id: 'staff-1',
  firstName: 'Ada',
  lastName: 'Okafor',
  email: 'ada.okafor@example.com',
  role: StaffRole.manager,
  status: StaffStatus.active,
);

const _draft = StaffDraft(
  firstName: 'Ekong',
  lastName: 'Silas',
  email: 'ekong@slp.africa',
  phone: '08034112290',
  role: StaffRole.admin,
);

/// A failing HTTP response, as Dio raises it.
DioException _httpFailure(int statusCode, {Object? body}) {
  final options = RequestOptions(path: '/staff');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(
      requestOptions: options,
      statusCode: statusCode,
      data: body,
    ),
  );
}

void main() {
  late MockStaffRemoteDataSource remote;
  late StaffRepositoryImpl repository;

  setUpAll(() => registerFallbackValue(_draft));

  setUp(() {
    remote = MockStaffRemoteDataSource();
    repository = StaffRepositoryImpl(remote);
  });

  group('fetchStaff', () {
    test('returns Ok with the page on success', () async {
      when(
        () => remote.fetchStaff(page: 1, perPage: 20),
      ).thenAnswer((_) async => const StaffPage(items: [_staff]));

      final result = await repository.fetchStaff(page: 1, perPage: 20);

      expect(result.isOk, isTrue);
      expect(result.valueOrNull?.items, [_staff]);
    });

    test('treats a 404 as an empty list, not an error', () async {
      // The API documents 404 on this endpoint as "No staff members found".
      when(
        () => remote.fetchStaff(page: 1, perPage: 20),
      ).thenThrow(_httpFailure(404));

      final result = await repository.fetchStaff(page: 1, perPage: 20);

      expect(result.isOk, isTrue);
      expect(result.valueOrNull?.isEmpty, isTrue);
      expect(result.valueOrNull?.hasMore, isFalse);
    });

    test('returns Err for any other failure', () async {
      when(
        () => remote.fetchStaff(page: 1, perPage: 20),
      ).thenThrow(_httpFailure(500));

      final result = await repository.fetchStaff(page: 1, perPage: 20);

      expect(result.isErr, isTrue);
      expect(result.failureOrNull?.type, FailureType.server);
    });

    test('maps a connection error to a network failure', () async {
      when(() => remote.fetchStaff(page: 1, perPage: 20)).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/staff'),
          type: DioExceptionType.connectionError,
        ),
      );

      final result = await repository.fetchStaff(page: 1, perPage: 20);

      expect(result.failureOrNull?.type, FailureType.network);
      expect(result.failureOrNull?.message, contains('offline'));
    });
  });

  group('createStaff', () {
    test('returns Ok when the API accepts the record', () async {
      // POST /staff returns no `data`, so success carries no record.
      when(() => remote.createStaff(any())).thenAnswer((_) async {});

      final result = await repository.createStaff(_draft);

      expect(result.isOk, isTrue);
      expect(result.failureOrNull, isNull);
    });

    test('surfaces the API message on a duplicate email', () async {
      when(() => remote.createStaff(any())).thenThrow(
        _httpFailure(409, body: {
          'status': 'fail',
          'message': 'A staff member with this email already exists.',
        }),
      );

      final result = await repository.createStaff(_draft);

      expect(result.failureOrNull?.type, FailureType.conflict);
      expect(
        result.failureOrNull?.message,
        'A staff member with this email already exists.',
      );
    });

    test('does not treat a create 404 as an empty result', () async {
      // The empty-list rule is specific to the list endpoint.
      when(() => remote.createStaff(any())).thenThrow(_httpFailure(404));

      final result = await repository.createStaff(_draft);

      expect(result.isErr, isTrue);
      expect(result.failureOrNull?.type, FailureType.notFound);
    });
  });

  group('updateStaff', () {
    test('returns Ok with the updated record', () async {
      when(
        () => remote.updateStaff(id: 'staff-1', draft: any(named: 'draft')),
      ).thenAnswer((_) async => _staff);

      final result = await repository.updateStaff(id: 'staff-1', draft: _draft);

      expect(result.valueOrNull, _staff);
    });

    test('returns Err when the record no longer exists', () async {
      when(
        () => remote.updateStaff(id: 'gone', draft: any(named: 'draft')),
      ).thenThrow(_httpFailure(404));

      final result = await repository.updateStaff(id: 'gone', draft: _draft);

      expect(result.failureOrNull?.type, FailureType.notFound);
    });
  });

  group('deactivateStaff', () {
    test('returns Ok with the deactivated record', () async {
      when(() => remote.deactivateStaff('staff-1')).thenAnswer(
        (_) async => const Staff(
          id: 'staff-1',
          firstName: 'Ada',
          lastName: 'Okafor',
          email: 'ada.okafor@example.com',
          role: StaffRole.manager,
          status: StaffStatus.inactive,
        ),
      );

      final result = await repository.deactivateStaff('staff-1');

      expect(result.isOk, isTrue);
      expect(result.valueOrNull?.isActive, isFalse);
    });

    test('returns Err on failure', () async {
      when(() => remote.deactivateStaff('gone')).thenThrow(_httpFailure(500));

      final result = await repository.deactivateStaff('gone');

      expect(result.failureOrNull?.type, FailureType.server);
    });
  });

  test('never leaks a raw exception through any method', () async {
    when(
      () => remote.fetchStaff(page: 1, perPage: 20),
    ).thenThrow(Exception('internal detail leaked here'));
    when(() => remote.createStaff(any())).thenThrow(StateError('bad state'));

    final failures = [
      (await repository.fetchStaff(page: 1, perPage: 20)).failureOrNull,
      (await repository.createStaff(_draft)).failureOrNull,
    ];

    for (final failure in failures) {
      expect(failure, isNotNull);
      expect(failure!.message.toLowerCase(), isNot(contains('exception')));
      expect(failure.message.toLowerCase(), isNot(contains('internal detail')));
      expect(failure.message, isNotEmpty);
    }
  });
}
