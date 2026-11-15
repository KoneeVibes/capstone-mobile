import 'package:equatable/equatable.dart';

/// One line in a case conversation, as `conversation.chat` carries it.
///
/// Who the sender is to the reader is `ChatConversation.authorOf`.
class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    this.senderName,
    this.sentAt,
    this.isPending = false,
  });

  final String id;
  final String senderId;
  final String text;

  /// Sent on a read of the case, not in the answer to a send (live, 15 Nov
  /// 2026), so a just-sent message has none until the next read.
  final String? senderName;
  final DateTime? sentAt;

  /// Shown at once while the send is in flight; the server's copy replaces it.
  final bool isPending;

  @override
  List<Object?> get props => [
    id,
    senderId,
    text,
    senderName,
    sentAt,
    isPending,
  ];
}
