import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:propertyintelmobileapp/core/network/api_client.dart';
import 'package:propertyintelmobileapp/core/network/api_response.dart';
import 'package:propertyintelmobileapp/core/session/staff_role.dart';
import 'package:propertyintelmobileapp/features/staff/data/datasources/staff_remote_datasource.dart';
import 'package:propertyintelmobileapp/features/staff/domain/entities/staff.dart';
import 'package:propertyintelmobileapp/features/staff/domain/entities/staff_draft.dart';

class MockApiClient extends Mock implements ApiClient {}

const _staffJson = <String, dynamic>{
  'id': 'staff-1',
  'firstName': 'Ada',
  'middleName': 'Grace',
  'lastName': 'Okafor',
  'email': 'ada.okafor@example.com',
  'phone': '+2348012345678',
  'role': 'manager',
  'status': 'active',
};

const _draft = StaffDraft(
  firstName: 'Ekong',
  lastName: 'Silas',
  email: 'ekong@slp.africa',
  phone: '08034112290',
  role: StaffRole.admin,
);

void main() {
  late MockApiClient client;
  late StaffRemoteDataSource dataSource;

  setUp(() {
    client = MockApiClient();
    dataSource = StaffRemoteDataSourceImpl(client);
  });

  /// Stubs a list call, running the decoder the datasource supplied against
  /// [data] so the decoding wiring is exercised rather than bypassed.
  void stubList(List<Object?> data, {PageMeta? meta}) {
    when(
      () => client.get<List<Staff>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((invocation) async {
      final decoder =
          invocation.namedArguments[#decoder] as List<Staff> Function(Object?);
      return ApiResponse<List<Staff>>(
        status: 'success',
        message: 'success',
        data: decoder(data),
        meta: meta,
      );
    });
  }

  /// Builds a single-record answer, running the datasource's own decoder.
  ApiResponse<Staff> Function(Invocation) singleAnswer(
    Map<String, dynamic> json,
  ) => (invocation) {
    final decoder = invocation.namedArguments[#decoder] as Staff Function(Object?);
    return ApiResponse<Staff>(
      status: 'success',
      message: 'success',
      data: decoder(json),
    );
  };

  group('fetchStaff', () {
    test('requests the staff path with page and perPage', () async {
      stubList([_staffJson]);

      await dataSource.fetchStaff(page: 2, perPage: 20);

      final captured = verify(
        () => client.get<List<Staff>>(
          captureAny(),
          queryParameters: captureAny(named: 'queryParameters'),
          decoder: any(named: 'decoder'),
        ),
      ).captured;

      expect(captured[0], '/staff');
      expect(captured[1], {'page': 2, 'perPage': 20});
    });

    test('decodes records and carries the pagination meta through', () async {
      const meta = PageMeta(page: 1, perPage: 10, total: 25, totalPages: 3);
      stubList([_staffJson], meta: meta);

      final page = await dataSource.fetchStaff(page: 1, perPage: 10);

      expect(page.items, hasLength(1));
      expect(page.items.single.firstName, 'Ada');
      expect(page.meta, meta);
      expect(page.hasMore, isTrue);
    });

    test('returns an empty page when the API sends no records', () async {
      stubList([]);

      final page = await dataSource.fetchStaff(page: 1, perPage: 10);

      expect(page.isEmpty, isTrue);
      expect(page.hasMore, isFalse);
    });

    test('lets a DioException propagate rather than catching it', () async {
      when(
        () => client.get<List<Staff>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          decoder: any(named: 'decoder'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/staff'),
          type: DioExceptionType.connectionError,
        ),
      );

      await expectLater(
        dataSource.fetchStaff(page: 1, perPage: 10),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('fetchStaffMember', () {
    test('requests the record by id', () async {
      when(
        () => client.get<Staff>(any(), decoder: any(named: 'decoder')),
      ).thenAnswer((i) async => singleAnswer(_staffJson)(i));

      final staff = await dataSource.fetchStaffMember('staff-1');

      expect(staff.id, 'staff-1');
      verify(
        () => client.get<Staff>('/staff/staff-1', decoder: any(named: 'decoder')),
      ).called(1);
    });
  });

  group('createStaff', () {
    /// `POST /staff` replies `{status, message}` with no `data` node.
    void stubCreate() {
      when(
        () => client.post<void>(
          any(),
          data: any(named: 'data'),
          decoder: any(named: 'decoder'),
        ),
      ).thenAnswer((invocation) async {
        final decoder =
            invocation.namedArguments[#decoder] as void Function(Object?);
        // Run the datasource's own decoder against the record-less body it
        // actually receives, then hand back the empty envelope.
        decoder(null);
        return const ApiResponse<void>(
          status: 'success',
          message: 'Staff successfully added',
          data: null,
        );
      });
    }

    test('posts multipart form data to the staff path', () async {
      stubCreate();

      await dataSource.createStaff(_draft);

      final captured = verify(
        () => client.post<void>(
          captureAny(),
          data: captureAny(named: 'data'),
          decoder: any(named: 'decoder'),
        ),
      ).captured;

      expect(captured[0], '/staff');
      expect(captured[1], isA<FormData>());

      final fields = {
        for (final field in (captured[1] as FormData).fields)
          field.key: field.value,
      };
      expect(fields['firstName'], 'Ekong');
      expect(fields['role'], 'admin');
    });

    test('succeeds even though the response carries no record', () async {
      // Regression: decoding a record here failed a create that had actually
      // succeeded, pushing the user into a duplicate-email retry.
      stubCreate();

      await expectLater(dataSource.createStaff(_draft), completes);
    });
  });

  group('updateStaff', () {
    test('puts multipart form data to the record path', () async {
      when(
        () => client.put<Staff>(
          any(),
          data: any(named: 'data'),
          decoder: any(named: 'decoder'),
        ),
      ).thenAnswer((i) async => singleAnswer(_staffJson)(i));

      await dataSource.updateStaff(id: 'staff-1', draft: _draft);

      verify(
        () => client.put<Staff>(
          '/staff/staff-1',
          data: any(named: 'data', that: isA<FormData>()),
          decoder: any(named: 'decoder'),
        ),
      ).called(1);
    });
  });

  group('deactivateStaff', () {
    test('deletes the record by id', () async {
      when(
        () => client.delete<Staff>(any(), decoder: any(named: 'decoder')),
      ).thenAnswer((i) async => singleAnswer(_staffJson)(i));

      await dataSource.deactivateStaff('staff-1');

      verify(
        () => client.delete<Staff>(
          '/staff/staff-1',
          decoder: any(named: 'decoder'),
        ),
      ).called(1);
    });
  });
}
