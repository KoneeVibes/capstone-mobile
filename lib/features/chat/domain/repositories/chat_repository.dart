import '../../../../core/utils/result.dart';
import '../entities/chat_message.dart';
import '../entities/chat_thread.dart';

/// A case's conversation, which the API keeps on the case itself.
abstract class ChatRepository {
  Future<Result<ChatThread>> fetchThread(String caseId);

  /// Returns the message as the server stored it. A closed conversation
  /// refuses with a conflict.
  Future<Result<ChatMessage>> sendMessage(String caseId, String text);

  /// Opens a closed conversation or closes an open one; the case's status
  /// moves with it. The holder of the case only.
  Future<Result<void>> toggleConversation(String caseId);
}
