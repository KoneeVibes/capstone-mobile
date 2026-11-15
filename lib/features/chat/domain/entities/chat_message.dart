import 'package:equatable/equatable.dart';

/// One line in a case conversation, as `conversation.chat` carries it.
///
/// The wire has no author name, only [senderId]; who that is to the reader is
/// `ChatConversation.authorOf`.
class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    this.sentAt,
    this.isPending = false,
  });

  final String id;
  final String senderId;
  final String text;
  final DateTime? sentAt;

  /// Shown at once while the send is in flight; the server's copy replaces it.
  final bool isPending;

  @override
  List<Object?> get props => [id, senderId, text, sentAt, isPending];
}
