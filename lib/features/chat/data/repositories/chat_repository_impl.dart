import '../../../../core/utils/error/error_handler.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_thread.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_datasource.dart';

class ChatRepositoryImpl implements ChatRepository {
  const ChatRepositoryImpl(this._remote);

  final ChatRemoteDataSource _remote;

  @override
  Future<Result<ChatThread>> fetchThread(String caseId) =>
      _guard(() => _remote.fetchThread(caseId));

  @override
  Future<Result<ChatMessage>> sendMessage(String caseId, String text) =>
      _guard(() => _remote.sendMessage(caseId, text));

  @override
  Future<Result<void>> toggleConversation(String caseId) =>
      _guard(() => _remote.toggleConversation(caseId));

  static Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Ok(await action());
    } on Object catch (error, stackTrace) {
      return Err(ErrorHandler.from(error, stackTrace));
    }
  }
}
