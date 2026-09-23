import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:propertyintelmobileapp/core/network/api_client.dart';
import 'package:propertyintelmobileapp/core/network/api_response.dart';
import 'package:propertyintelmobileapp/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:propertyintelmobileapp/features/dashboard/data/models/case_address_model.dart';
import 'package:propertyintelmobileapp/features/dashboard/data/models/staff_name_model.dart';
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
}
