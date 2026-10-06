import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:propertyintelmobileapp/core/network/api_client.dart';
import 'package:propertyintelmobileapp/core/network/api_response.dart';
import 'package:propertyintelmobileapp/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:propertyintelmobileapp/features/dashboard/data/models/case_address_model.dart';
import 'package:propertyintelmobileapp/features/dashboard/data/models/case_status_row_model.dart';
import 'package:propertyintelmobileapp/features/dashboard/data/models/staff_name_model.dart';
import 'package:propertyintelmobileapp/features/dashboard/domain/entities/case_overview.dart';
import 'package:propertyintelmobileapp/features/dashboard/domain/entities/tracked_case.dart';

import '../../dashboard_fixtures.dart';

class MockApiClient extends Mock implements ApiClient {}

DioException _httpFailure(int statusCode) {
  final options = RequestOptions(path: '/case');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(
      requestOptions: options,
      statusCode: statusCode,
    ),
  );
}

ApiResponse<List<T>> _page<T>(List<T> rows) => ApiResponse<List<T>>(
  status: 'success',
  message: 'success',
  data: rows,
  meta: const PageMeta(page: 1, perPage: 100, total: 1, totalPages: 1),
);

void main() {
  late MockApiClient client;
  late DashboardRemoteDataSourceImpl source;

  setUp(() {
    client = MockApiClient();
    source = DashboardRemoteDataSourceImpl(client);
  });

  void stubTracking(Map<String, dynamic> json) {
    when(
      () => client.get<TrackedCase>(any(), decoder: any(named: 'decoder')),
    ).thenAnswer((invocation) async {
      final decoder =
          invocation.namedArguments[#decoder] as TrackedCase Function(Object?);
      return ApiResponse<TrackedCase>(
        status: 'success',
        message: 'Case tracking details retrieved successfully.',
        data: decoder(json),
      );
    });
  }

  /// [active] answers the unfiltered request; [closed] the `filter=closed` one,
  /// which 404s when left null, as the live API does when nothing matches.
  void stubCases(List<Object?> active, {List<Object?>? closed}) {
    when(
      () => client.get<List<CaseAddressModel>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((invocation) async {
      final query =
          invocation.namedArguments[#queryParameters] as Map<String, dynamic>;
      final decoder =
          invocation.namedArguments[#decoder]
              as List<CaseAddressModel> Function(Object?);
      if (query.containsKey('filter')) {
        if (closed == null) throw _httpFailure(404);
        return _page(decoder(closed));
      }
      return _page(decoder(active));
    });
  }

  void stubStaff(List<Object?> rows) {
    when(
      () => client.get<List<StaffNameModel>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((invocation) async {
      final decoder =
          invocation.namedArguments[#decoder]
              as List<StaffNameModel> Function(Object?);
      return _page(decoder(rows));
    });
  }

  final bareHistory = {...trackingJson, 'statusHistory': const <Object?>[]};

  test('requests the tracking path', () async {
    stubTracking(bareHistory);
    stubCases(const []);

    await source.trackCase('PI-URF8T7C2');

    verify(
      () => client.get<TrackedCase>(
        '/case/track/PI-URF8T7C2',
        decoder: any(named: 'decoder'),
      ),
    ).called(1);
  });

  test('joins the address from the case list and the assignee names', () async {
    stubTracking(trackingJson);
    stubCases([
      caseRowJson(trackingId: 'PI-OTHER0000', address: 'Wrong'),
      caseRowJson(),
    ]);
    stubStaff([staffRowJson()]);

    final tracked = await source.trackCase('PI-URF8T7C2');

    expect(tracked.address, '5 Kayode Abraham, Off Ligali Ayorinde');
    expect(tracked.history[2].assigneeName, 'Ada Okafor');
    expect(tracked.history[3].assigneeName, isNull);
  });

  test('finds the address among closed cases too', () async {
    stubTracking(bareHistory);
    stubCases(const [], closed: [caseRowJson()]);

    final tracked = await source.trackCase('PI-URF8T7C2');

    expect(tracked.address, '5 Kayode Abraham, Off Ligali Ayorinde');
  });

  test('still returns the case when both joins fail', () async {
    stubTracking(trackingJson);
    when(
      () => client.get<List<CaseAddressModel>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
        decoder: any(named: 'decoder'),
      ),
    ).thenThrow(_httpFailure(503));
    when(
      () => client.get<List<StaffNameModel>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
        decoder: any(named: 'decoder'),
      ),
    ).thenThrow(_httpFailure(503));

    final tracked = await source.trackCase('PI-URF8T7C2');

    expect(tracked.address, isNull);
    expect(tracked.history, hasLength(4));
  });

  test('skips the staff request when nobody was ever assigned', () async {
    stubTracking(bareHistory);
    stubCases(const []);

    await source.trackCase('PI-URF8T7C2');

    verifyNever(
      () => client.get<List<StaffNameModel>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
        decoder: any(named: 'decoder'),
      ),
    );
  });

  test('lets a failed lookup propagate', () async {
    when(
      () => client.get<TrackedCase>(any(), decoder: any(named: 'decoder')),
    ).thenThrow(_httpFailure(404));

    expect(() => source.trackCase('PI-8K4M2QAA'), throwsA(isA<DioException>()));
  });

  group('fetchOverview', () {
    /// Answers the unfiltered and `filter=closed` requests separately; a null
    /// side answers 404, as the live list does when nothing matches.
    void stubRows({List<Object?>? active, List<Object?>? closed}) {
      when(
        () => client.get<List<CaseStatusRowModel>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          decoder: any(named: 'decoder'),
        ),
      ).thenAnswer((invocation) async {
        final query =
            invocation.namedArguments[#queryParameters] as Map<String, dynamic>;
        final rows = query.containsKey('filter') ? closed : active;
        if (rows == null) throw _httpFailure(404);
        final decoder =
            invocation.namedArguments[#decoder]
                as List<CaseStatusRowModel> Function(Object?);
        return _page(decoder(rows));
      });
    }

    test('counts each status into its card', () async {
      stubRows(
        active: [
          {'id': 'a', 'status': 'submitted'},
          {'id': 'b', 'status': 'pending-information'},
          {'id': 'c', 'status': 'assigned'},
          {'id': 'd', 'status': 'under-review'},
          {'id': 'e', 'status': 'suspended'},
        ],
        closed: [
          {'id': 'f', 'status': 'closed'},
        ],
      );

      expect(
        await source.fetchOverview(),
        const CaseOverview(
          total: 6,
          reportsReady: 1,
          inProgress: 2,
          needsInput: 2,
        ),
      );
    });

    test('counts a case both requests return once', () async {
      stubRows(
        active: [
          {'id': 'a', 'status': 'closed'},
        ],
        closed: [
          {'id': 'a', 'status': 'closed'},
        ],
      );

      expect((await source.fetchOverview()).total, 1);
    });

    test('reads 404s as a client with no cases yet', () async {
      stubRows();

      expect(
        await source.fetchOverview(),
        const CaseOverview(
          total: 0,
          reportsReady: 0,
          inProgress: 0,
          needsInput: 0,
        ),
      );
    });

    test('lets any other failure propagate', () async {
      when(
        () => client.get<List<CaseStatusRowModel>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          decoder: any(named: 'decoder'),
        ),
      ).thenThrow(_httpFailure(500));

      expect(source.fetchOverview, throwsA(isA<DioException>()));
    });
  });
}
