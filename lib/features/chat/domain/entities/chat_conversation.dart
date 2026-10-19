import 'package:equatable/equatable.dart';

import 'chat_message.dart';

/// Whether a case conversation is accepting messages.
///
/// The flow is deliberate: a conversation must be *opened* before anyone can
/// type, and *closed* once it has run its course.
enum ChatStatus { notOpened, open, closed }

/// A case conversation: its state and the lines sent so far.
class ChatConversation extends Equatable {
  const ChatConversation({required this.status, required this.messages});

  final ChatStatus status;
  final List<ChatMessage> messages;

  /// Typing and sending are only allowed while open.
  bool get canType => status == ChatStatus.open;

  /// "Open conversation" is live unless it is already open.
  bool get canOpen => status != ChatStatus.open;

  /// "Close conversation" is live only while open.
  bool get canClose => status == ChatStatus.open;

  /// Whether to show the "chat closed" marker.
  bool get isClosed => status == ChatStatus.closed;

  ChatConversation copyWith({
    ChatStatus? status,
    List<ChatMessage>? messages,
  }) => ChatConversation(
    status: status ?? this.status,
    messages: messages ?? this.messages,
  );

  @override
  List<Object?> get props => [status, messages];
}
