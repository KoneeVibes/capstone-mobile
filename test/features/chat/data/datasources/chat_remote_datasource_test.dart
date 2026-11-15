import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:propertyintelmobileapp/core/network/api_client.dart';
import 'package:propertyintelmobileapp/core/network/api_response.dart';
import 'package:propertyintelmobileapp/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:propertyintelmobileapp/features/chat/domain/entities/chat_message.dart';
import 'package:propertyintelmobileapp/features/chat/domain/entities/chat_thread.dart';

import '../../chat_fixtures.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient client;
  late ChatRemoteDataSourceImpl source;

  setUp(() {
    client = MockApiClient();
    source = ChatRemoteDataSourceImpl(client);
  });

  test('reads the conversation from GET /case/{id}', () async {
    when(
      () => client.get<ChatThread>(any(), decoder: any(named: 'decoder')),
    ).thenAnswer((invocation) async {
      final decoder =
          invocation.namedArguments[#decoder] as ChatThread Function(Object?);
      return ApiResponse<ChatThread>(
        status: 'success',
        message: 'success',
        data: decoder(openCaseJson),
      );
    });

    expect(await source.fetchThread('case-1'), thread());
    verify(
      () => client.get<ChatThread>(
        '/case/case-1',
        decoder: any(named: 'decoder'),
      ),
    ).called(1);
  });

  test('POSTs the text to /case/{id}/message', () async {
    when(
      () => client.post<ChatMessage>(
        any(),
        data: any(named: 'data'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer(
      (_) async => ApiResponse<ChatMessage>(
        status: 'success',
        message: 'Message submitted successfully.',
        data: clientMessage,
      ),
    );

    expect(
      await source.sendMessage('case-1', 'Sending it now.'),
      clientMessage,
    );
    verify(
      () => client.post<ChatMessage>(
        '/case/case-1/message',
        data: {'text': 'Sending it now.'},
        decoder: any(named: 'decoder'),
      ),
    ).called(1);
  });

  test('toggles with PATCH /case/{id} pending-information', () async {
    when(
      () => client.patch<void>(
        any(),
        data: any(named: 'data'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer(
      (_) async => const ApiResponse<void>(
        status: 'success',
        message: 'Case updated successfully.',
        data: null,
      ),
    );

    await source.toggleConversation('case-1');

    verify(
      () => client.patch<void>(
        '/case/case-1',
        data: {'status': 'pending-information'},
        decoder: any(named: 'decoder'),
      ),
    ).called(1);
  });
}
