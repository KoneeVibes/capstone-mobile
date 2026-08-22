import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:propertyintelmobileapp/core/utils/error/failure_type.dart';
import 'package:propertyintelmobileapp/features/cases/data/datasources/cases_datasource.dart';
import 'package:propertyintelmobileapp/features/cases/data/repositories/cases_repository_impl.dart';
import 'package:propertyintelmobileapp/features/cases/domain/entities/case_status.dart';

import '../../case_fixtures.dart';

class MockCasesDataSource extends Mock implements CasesDataSource {}

const _assignee = ada;

final _case = buildCase(id: 'case-101');

/// A failing HTTP response, as Dio raises it.
DioException _httpFailure(int statusCode, {Object? body}) {
  final options = RequestOptions(path: '/case');
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
  late MockCasesDataSource source;
  late CasesRepositoryImpl repository;

  setUp(() {
    source = MockCasesDataSource();
    repository = CasesRepositoryImpl(source);
  });

  group('fetchCases', () {
    test('returns Ok with the cases on success', () async {
      when(source.fetchCases).thenAnswer((_) async => [_case]);

      final result = await repository.fetchCases();

      expect(result.isOk, isTrue);
      expect(result.valueOrNull, [_case]);
    });

    test('treats a 404 as an empty list, not an error', () async {
      when(source.fetchCases).thenThrow(_httpFailure(404));

      final result = await repository.fetchCases();

      expect(result.isOk, isTrue);
      expect(result.valueOrNull, isEmpty);
    });

    test('returns Err for any other failure', () async {
      when(source.fetchCases).thenThrow(_httpFailure(500));

      final result = await repository.fetchCases();

      expect(result.isErr, isTrue);
      expect(result.failureOrNull!.type, FailureType.server);
    });

    test('never lets an exception escape', () async {
      when(source.fetchCases).thenThrow(Exception('boom'));

      final result = await repository.fetchCases();

      expect(result.isErr, isTrue);
      expect(result.failureOrNull!.type, FailureType.unknown);
    });
  });

  group('fetchCase', () {
    test('returns Ok with the case on success', () async {
      when(() => source.fetchCase('case-101')).thenAnswer((_) async => _case);

      final result = await repository.fetchCase('case-101');

      expect(result.valueOrNull, _case);
    });

    test('surfaces a 404 as a notFound failure', () async {
      when(() => source.fetchCase(any())).thenThrow(_httpFailure(404));

      final result = await repository.fetchCase('nope');

      expect(result.isErr, isTrue);
      expect(result.failureOrNull!.type, FailureType.notFound);
    });
  });

  group('fetchAssignees', () {
    test('returns Ok with the team on success', () async {
      when(source.fetchAssignees).thenAnswer((_) async => [_assignee]);

      final result = await repository.fetchAssignees();

      expect(result.valueOrNull, [_assignee]);
    });

    test('returns Err on failure', () async {
      when(source.fetchAssignees).thenThrow(_httpFailure(503));

      final result = await repository.fetchAssignees();

      expect(result.failureOrNull!.type, FailureType.server);
    });
  });

  group('assignCase', () {
    test('returns Ok with the updated case', () async {
      final assigned = buildCase(
        id: 'case-101',
        status: CaseStatus.assigned,
        assignee: _assignee,
      );
      when(
        () => source.assignCase(caseId: 'case-101', assigneeId: _assignee.id),
      ).thenAnswer((_) async => assigned);

      final result = await repository.assignCase(
        caseId: 'case-101',
        assigneeId: _assignee.id,
      );

      expect(result.valueOrNull, assigned);
    });

    test('prefers the server message when it reads like copy', () async {
      when(
        () => source.assignCase(
          caseId: any(named: 'caseId'),
          assigneeId: any(named: 'assigneeId'),
        ),
      ).thenThrow(
        _httpFailure(
          409,
          body: const {
            'status': 'fail',
            'message': 'That case is already assigned to someone else.',
          },
        ),
      );

      final result = await repository.assignCase(
        caseId: 'case-101',
        assigneeId: 'staff-1',
      );

      expect(result.isErr, isTrue);
      expect(
        result.failureOrNull!.message,
        'That case is already assigned to someone else.',
      );
      expect(result.failureOrNull!.type, FailureType.conflict);
    });
  });
}
