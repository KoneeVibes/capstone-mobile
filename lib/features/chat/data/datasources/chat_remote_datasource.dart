import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_thread.dart';
import '../models/chat_thread_model.dart';

/// The conversation lives on the case, so reads and the open/close toggle go
/// to `/case/{id}`; only sending has a path of its own. Throws.
abstract class ChatRemoteDataSource {
  Future<ChatThread> fetchThread(String caseId);

  Future<ChatMessage> sendMessage(String caseId, String text);

  Future<void> toggleConversation(String caseId);
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  const ChatRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<ChatThread> fetchThread(String caseId) async {
    final response = await _client.get<ChatThread>(
      ApiEndpoints.caseById(caseId),
      decoder: ChatThreadModel.fromData,
    );
    return response.data;
  }

  @override
  Future<ChatMessage> sendMessage(String caseId, String text) async {
    final response = await _client.post<ChatMessage>(
      ApiEndpoints.caseMessages(caseId),
      data: {'text': text},
      decoder: ChatThreadModel.sentFromData,
    );
    return response.data;
  }

  /// The answer is not decoded: the notifier re-reads the case after it.
  @override
  Future<void> toggleConversation(String caseId) async {
    await _client.patch<void>(
      ApiEndpoints.caseById(caseId),
      data: ChatThreadModel.toggleBody,
      decoder: (_) {},
    );
  }
}
