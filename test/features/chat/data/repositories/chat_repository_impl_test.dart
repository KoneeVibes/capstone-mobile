import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:propertyintelmobileapp/core/utils/error/failure_type.dart';
import 'package:propertyintelmobileapp/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:propertyintelmobileapp/features/chat/data/repositories/chat_repository_impl.dart';

import '../../chat_fixtures.dart';

class MockChatRemoteDataSource extends Mock implements ChatRemoteDataSource {}

DioException _httpFailure(int statusCode) {
  final options = RequestOptions(path: '/case/case-1');
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
  late MockChatRemoteDataSource remote;
  late ChatRepositoryImpl repository;

  setUp(() {
    remote = MockChatRemoteDataSource();
    repository = ChatRepositoryImpl(remote);
  });

  test('returns the thread, or a failure', () async {
    when(() => remote.fetchThread('case-1')).thenAnswer((_) async => thread());
    expect((await repository.fetchThread('case-1')).valueOrNull, thread());

    when(() => remote.fetchThread('case-1')).thenThrow(_httpFailure(404));
    expect(
      (await repository.fetchThread('case-1')).failureOrNull?.type,
      FailureType.notFound,
    );
  });

  test('a send to a closed conversation is a conflict', () async {
    when(
      () => remote.sendMessage('case-1', 'Hi'),
    ).thenAnswer((_) async => clientMessage);
    expect(
      (await repository.sendMessage('case-1', 'Hi')).valueOrNull,
      clientMessage,
    );

    when(() => remote.sendMessage('case-1', 'Hi')).thenThrow(_httpFailure(409));
    expect(
      (await repository.sendMessage('case-1', 'Hi')).failureOrNull?.type,
      FailureType.conflict,
    );
  });

  test('a toggle by anyone but the holder is refused', () async {
    when(() => remote.toggleConversation('case-1')).thenAnswer((_) async {});
    expect((await repository.toggleConversation('case-1')).isOk, isTrue);

    when(
      () => remote.toggleConversation('case-1'),
    ).thenThrow(_httpFailure(403));
    expect(
      (await repository.toggleConversation('case-1')).failureOrNull?.type,
      FailureType.forbidden,
    );
  });
}
