import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:propertyintelmobileapp/core/utils/error/app_failures.dart';
import 'package:propertyintelmobileapp/core/utils/error/failure_type.dart';
import 'package:propertyintelmobileapp/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:propertyintelmobileapp/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:propertyintelmobileapp/features/profile/domain/entities/profile_draft.dart';

import '../../profile_fixtures.dart';

class MockProfileRemoteDataSource extends Mock
    implements ProfileRemoteDataSource {}

DioException _httpFailure(int statusCode) {
  final options = RequestOptions(path: '/profile');
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
  late MockProfileRemoteDataSource remote;
  late ProfileRepositoryImpl repository;

  setUpAll(() => registerFallbackValue(const ProfileDraft()));

  setUp(() {
    remote = MockProfileRemoteDataSource();
    repository = ProfileRepositoryImpl(remote);
  });

  test('returns the profile', () async {
    when(() => remote.fetchProfile()).thenAnswer((_) async => profile);

    expect((await repository.fetchProfile()).valueOrNull, profile);
  });

  test('converts a failed read', () async {
    when(() => remote.fetchProfile()).thenThrow(_httpFailure(404));

    final failure = (await repository.fetchProfile()).failureOrNull;

    expect(failure?.type, FailureType.notFound);
  });

  test('returns the saved record, or a failure', () async {
    when(() => remote.updateProfile(any())).thenAnswer((_) async => profile);
    expect(
      (await repository.updateProfile(
        const ProfileDraft(firstName: 'Ada'),
      )).valueOrNull,
      profile,
    );

    when(() => remote.updateProfile(any())).thenThrow(_httpFailure(400));
    expect(
      (await repository.updateProfile(
        const ProfileDraft(firstName: 'Ada'),
      )).isErr,
      isTrue,
    );
  });

  test('cannot delete an account yet', () async {
    expect(
      (await repository.deleteAccount()).failureOrNull,
      AppFailures.accountDeletionUnavailable,
    );
    verifyZeroInteractions(remote);
  });
}
