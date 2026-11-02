import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:propertyintelmobileapp/core/utils/error/failure_type.dart';
import 'package:propertyintelmobileapp/features/dashboard/data/datasources/dashboard_datasource.dart';
import 'package:propertyintelmobileapp/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:propertyintelmobileapp/features/dashboard/domain/entities/case_overview.dart';
import 'package:propertyintelmobileapp/features/dashboard/domain/entities/queue_overview.dart';
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

  test('returns Ok with either overview', () async {
    const client = CaseOverview(
      total: 7,
      reportsReady: 6,
      inProgress: 1,
      needsInput: 0,
    );
    const staff = QueueOverview(inQueue: 3, assignedThisWeek: 8);
    when(() => source.fetchClientOverview()).thenAnswer((_) async => client);
    when(() => source.fetchStaffOverview()).thenAnswer((_) async => staff);

    expect((await repository.fetchClientOverview()).valueOrNull, client);
    expect((await repository.fetchStaffOverview()).valueOrNull, staff);
  });

  test('turns a malformed overview into a failure', () async {
    when(
      () => source.fetchStaffOverview(),
    ).thenThrow(const FormatException('Expected staff metrics in "data".'));

    final result = await repository.fetchStaffOverview();

    expect(result.failureOrNull, isNotNull);
  });
}
