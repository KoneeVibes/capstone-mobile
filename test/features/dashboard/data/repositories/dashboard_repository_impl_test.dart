import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:propertyintelmobileapp/core/utils/error/failure_type.dart';
import 'package:propertyintelmobileapp/features/dashboard/data/datasources/dashboard_datasource.dart';
import 'package:propertyintelmobileapp/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:propertyintelmobileapp/features/dashboard/domain/entities/tracked_case.dart';
import 'package:propertyintelmobileapp/features/dashboard/domain/entities/tracking_status.dart';

class MockDashboardDataSource extends Mock implements DashboardDataSource {}

void main() {
  late MockDashboardDataSource source;
  late DashboardRepositoryImpl repository;

  setUp(() {
    source = MockDashboardDataSource();
    repository = DashboardRepositoryImpl(source);
  });

  test('returns Ok with the case on success', () async {
    const tracked = TrackedCase(
      trackingId: 'PI-URF8T7C2',
      status: TrackingStatus.assigned,
    );
    when(() => source.trackCase(any())).thenAnswer((_) async => tracked);

    final result = await repository.trackCase('PI-URF8T7C2');

    expect(result.valueOrNull, tracked);
  });

  test(
    'turns a 404 into a not-found failure carrying the server copy',
    () async {
      final options = RequestOptions(path: '/case/track/PI-8K4M2QAA');
      when(() => source.trackCase(any())).thenThrow(
        DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response<dynamic>(
            requestOptions: options,
            statusCode: 404,
            data: const {'status': 'fail', 'message': 'Case not found.'},
          ),
        ),
      );

      final result = await repository.trackCase('PI-8K4M2QAA');

      expect(result.failureOrNull?.type, FailureType.notFound);
      expect(result.failureOrNull?.message, 'Case not found.');
    },
  );
}
