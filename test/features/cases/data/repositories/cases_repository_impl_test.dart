import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:propertyintelmobileapp/core/utils/error/failure_type.dart';
import 'package:propertyintelmobileapp/core/utils/media_picker.dart';
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

  setUpAll(() => registerFallbackValue(<PickedMedia>[]));

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

  group('updateStatus', () {
    test('returns Ok with the moved case', () async {
      final accepted = buildCase(id: 'case-101', status: CaseStatus.accepted);
      when(
        () => source.updateStatus(
          caseId: 'case-101',
          status: CaseStatus.accepted,
        ),
      ).thenAnswer((_) async => accepted);

      final result = await repository.updateStatus(
        caseId: 'case-101',
        status: CaseStatus.accepted,
      );

      expect(result.valueOrNull, accepted);
    });

    test(
      'a refused transition is an Err carrying the server message',
      () async {
        when(
          () => source.updateStatus(
            caseId: any(named: 'caseId'),
            status: CaseStatus.closed,
          ),
        ).thenThrow(
          _httpFailure(
            409,
            body: const {
              'status': 'fail',
              'message': 'This case cannot be closed.',
            },
          ),
        );

        final result = await repository.updateStatus(
          caseId: 'case-101',
          status: CaseStatus.closed,
        );

        expect(result.failureOrNull!.message, 'This case cannot be closed.');
      },
    );
  });

  group('suspendCase', () {
    test('returns Ok with the suspended case', () async {
      final suspended = buildCase(id: 'case-101', status: CaseStatus.suspended);
      when(
        () => source.suspendCase(caseId: 'case-101'),
      ).thenAnswer((_) async => suspended);

      final result = await repository.suspendCase(caseId: 'case-101');

      expect(result.valueOrNull, suspended);
    });

    test('a refusal is an Err carrying the server message', () async {
      when(() => source.suspendCase(caseId: any(named: 'caseId'))).thenThrow(
        _httpFailure(
          409,
          body: const {
            'status': 'fail',
            'message': 'This case cannot be suspended.',
          },
        ),
      );

      final result = await repository.suspendCase(caseId: 'case-101');

      expect(result.failureOrNull!.message, 'This case cannot be suspended.');
    });
  });

  group('submitReport', () {
    test('returns Ok with the case under review', () async {
      final reviewed = buildCase(
        id: 'case-101',
        status: CaseStatus.underReview,
        reports: const ['https://x/report.pdf'],
      );
      when(
        () => source.submitReport(caseId: 'case-101', files: const []),
      ).thenAnswer((_) async => reviewed);

      final result = await repository.submitReport(
        caseId: 'case-101',
        files: const [],
      );

      expect(result.valueOrNull, reviewed);
    });

    test('never lets an exception escape', () async {
      when(
        () => source.submitReport(
          caseId: any(named: 'caseId'),
          files: any(named: 'files'),
        ),
      ).thenThrow(_httpFailure(403));

      final result = await repository.submitReport(
        caseId: 'case-101',
        files: const [],
      );

      expect(result.isErr, isTrue);
    });
  });

  group('searchCases', () {
    test('returns Ok with the matches', () async {
      when(() => source.searchCases('Zz')).thenAnswer((_) async => [_case]);

      final result = await repository.searchCases('Zz');

      expect(result.valueOrNull, [_case]);
    });

    test('returns Err when the search fails', () async {
      when(() => source.searchCases(any())).thenThrow(_httpFailure(500));

      final result = await repository.searchCases('Zz');

      expect(result.isErr, isTrue);
    });
  });
}
