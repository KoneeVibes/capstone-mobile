import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:propertyintelmobileapp/core/utils/error/failure_type.dart';
import 'package:propertyintelmobileapp/core/utils/media_picker.dart';
import 'package:propertyintelmobileapp/features/cases/data/datasources/disputes_datasource.dart';
import 'package:propertyintelmobileapp/features/cases/data/repositories/disputes_repository_impl.dart';
import 'package:propertyintelmobileapp/features/cases/domain/entities/case_dispute.dart';

class MockDisputesDataSource extends Mock implements DisputesDataSource {}

const _dispute = CaseDispute(
  id: 'dispute-1',
  caseId: 'case-1',
  title: 'Wrong plot',
  description: 'The survey covers the next plot.',
  status: DisputeStatus.open,
);

DioException _httpFailure(int statusCode, {Object? body}) {
  final options = RequestOptions(path: '/dispute');
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
  late MockDisputesDataSource source;
  late DisputesRepositoryImpl repository;

  setUpAll(() => registerFallbackValue(<PickedMedia>[]));

  setUp(() {
    source = MockDisputesDataSource();
    repository = DisputesRepositoryImpl(source);
  });

  group('fetchDisputes', () {
    test('returns the disputes', () async {
      when(
        () => source.fetchDisputes('case-1'),
      ).thenAnswer((_) async => [_dispute]);

      final result = await repository.fetchDisputes('case-1');

      expect(result.valueOrNull, [_dispute]);
    });

    test('reads "Case disputes not found" as none', () async {
      when(() => source.fetchDisputes('case-1')).thenThrow(
        _httpFailure(
          404,
          body: {'status': 'fail', 'message': 'Case disputes not found'},
        ),
      );

      final result = await repository.fetchDisputes('case-1');

      expect(result.isOk, isTrue);
      expect(result.valueOrNull, isEmpty);
    });

    test('any other failure is an Err', () async {
      when(() => source.fetchDisputes('case-1')).thenThrow(_httpFailure(500));

      final result = await repository.fetchDisputes('case-1');

      expect(result.isErr, isTrue);
    });
  });

  test('raise carries the server\'s refusal as the failure', () async {
    when(
      () => source.raiseDispute(
        caseId: any(named: 'caseId'),
        title: any(named: 'title'),
        description: any(named: 'description'),
        attachments: any(named: 'attachments'),
      ),
    ).thenThrow(
      _httpFailure(
        409,
        body: {'status': 'fail', 'message': 'Case already has an open dispute'},
      ),
    );

    final result = await repository.raiseDispute(
      caseId: 'case-1',
      title: 'Wrong plot',
      description: 'Next plot.',
    );

    expect(result.failureOrNull?.type, FailureType.conflict);
    expect(result.failureOrNull?.message, 'Case already has an open dispute');
  });

  test('reject returns the updated dispute', () async {
    when(
      () => source.rejectDispute(disputeId: 'dispute-1', note: 'Stands.'),
    ).thenAnswer((_) async => _dispute);

    final result = await repository.rejectDispute(
      disputeId: 'dispute-1',
      note: 'Stands.',
    );

    expect(result.valueOrNull, _dispute);
  });
}
