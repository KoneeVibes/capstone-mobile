import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:propertyintelmobileapp/core/network/api_client.dart';
import 'package:propertyintelmobileapp/core/network/api_response.dart';
import 'package:propertyintelmobileapp/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:propertyintelmobileapp/features/dashboard/domain/entities/case_overview.dart';
import 'package:propertyintelmobileapp/features/dashboard/domain/entities/queue_overview.dart';
import 'package:propertyintelmobileapp/features/dashboard/domain/entities/recent_search.dart';
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

  test('reads the tracking path alone, address and names included', () async {
    stubTracking(trackingJson);

    final tracked = await source.trackCase('PI-URF8T7C2');

    expect(tracked.address, '5 Kayode Abraham, Off Ligali Ayorinde');
    expect(tracked.history[2].assigneeName, 'Ada Okafor Regular');
    verify(
      () => client.get<TrackedCase>(
        '/case/track/PI-URF8T7C2',
        decoder: any(named: 'decoder'),
      ),
    ).called(1);
    verifyNoMoreInteractions(client);
  });

  test('lets a failed lookup propagate', () async {
    when(
      () => client.get<TrackedCase>(any(), decoder: any(named: 'decoder')),
    ).thenThrow(_httpFailure(404));

    expect(() => source.trackCase('PI-8K4M2QAA'), throwsA(isA<DioException>()));
  });

  group('recent searches', () {
    void stubHistory(List<Object?> rows) {
      when(
        () => client.get<List<RecentSearch>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          decoder: any(named: 'decoder'),
        ),
      ).thenAnswer((invocation) async {
        final decoder =
            invocation.namedArguments[#decoder]
                as List<RecentSearch> Function(Object?);
        return ApiResponse<List<RecentSearch>>(
          status: 'success',
          message: 'Search history retrieved successfully.',
          data: decoder(rows),
          meta: const PageMeta(page: 1, perPage: 20, total: 1, totalPages: 1),
        );
      });
    }

    test('reads one page of /search/history', () async {
      stubHistory([historyJson()]);

      final searches = await source.fetchRecentSearches(limit: 5);

      expect(searches.single.trackingId, 'PI-8APCC9W3');
      verify(
        () => client.get<List<RecentSearch>>(
          '/search/history',
          queryParameters: {'page': 1, 'perPage': 20},
          decoder: any(named: 'decoder'),
        ),
      ).called(1);
    });

    test('keeps the newest up to the limit', () async {
      stubHistory([
        for (final code in ['AAAAAAAA', 'BBBBBBBB', 'CCCCCCCC'])
          historyJson(id: code, query: 'PI-$code'),
      ]);

      final searches = await source.fetchRecentSearches(limit: 2);

      expect(searches.map((s) => s.id), ['AAAAAAAA', 'BBBBBBBB']);
    });

    test('lets a failure propagate', () {
      when(
        () => client.get<List<RecentSearch>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          decoder: any(named: 'decoder'),
        ),
      ).thenThrow(_httpFailure(500));

      expect(
        () => source.fetchRecentSearches(limit: 5),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('metrics', () {
    void stubMetrics<T>(Map<String, dynamic> data) {
      when(
        () => client.get<T>(any(), decoder: any(named: 'decoder')),
      ).thenAnswer((invocation) async {
        final decoder =
            invocation.namedArguments[#decoder] as T Function(Object?);
        return ApiResponse<T>(
          status: 'success',
          message: 'System metrics retrieved successfully.',
          data: decoder(data),
        );
      });
    }

    test('reads the client counts from /dashboard/metrics', () async {
      stubMetrics<CaseOverview>({
        'totalSearches': 7,
        'reportsReady': 6,
        'inProgress': 1,
        'needsYourInput': 0,
      });

      expect(
        await source.fetchClientOverview(),
        const CaseOverview(
          total: 7,
          reportsReady: 6,
          inProgress: 1,
          needsInput: 0,
        ),
      );
      verify(
        () => client.get<CaseOverview>(
          '/dashboard/metrics',
          decoder: any(named: 'decoder'),
        ),
      ).called(1);
    });

    test('reads the staff counts from /dashboard/metrics', () async {
      stubMetrics<QueueOverview>({'queue': 3, 'recent': 8});

      expect(
        await source.fetchStaffOverview(),
        const QueueOverview(inQueue: 3, assignedThisWeek: 8),
      );
      verify(
        () => client.get<QueueOverview>(
          '/dashboard/metrics',
          decoder: any(named: 'decoder'),
        ),
      ).called(1);
    });

    test('lets a failure propagate', () async {
      when(
        () => client.get<QueueOverview>(any(), decoder: any(named: 'decoder')),
      ).thenThrow(_httpFailure(500));

      expect(source.fetchStaffOverview, throwsA(isA<DioException>()));
    });
  });
}
