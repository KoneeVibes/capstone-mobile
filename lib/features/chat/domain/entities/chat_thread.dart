import 'package:equatable/equatable.dart';

import 'chat_message.dart';

/// The part of the case's status chat acts on. Its own enum, since chat may
/// not import the cases feature: only these two stages change what it offers.
enum ChatCaseStage { accepted, pendingInformation, other }

/// A case's conversation as the server holds it: the slice of `GET /case/{id}`
/// chat reads (ADR 0036).
class ChatThread extends Equatable {
  const ChatThread({
    required this.isOpen,
    required this.messages,
    required this.stage,
    this.assigneeId,
    this.applicantName,
  });

  final bool isOpen;

  /// Oldest first.
  final List<ChatMessage> messages;

  final ChatCaseStage stage;

  /// The staff member holding the case: the only one who may open or close.
  final String? assigneeId;

  final String? applicantName;

  /// With [message] at the end, unless a poll already brought it.
  ChatThread withMessage(ChatMessage message) {
    if (messages.any((existing) => existing.id == message.id)) return this;
    return ChatThread(
      isOpen: isOpen,
      messages: [...messages, message],
      stage: stage,
      assigneeId: assigneeId,
      applicantName: applicantName,
    );
  }

  @override
  List<Object?> get props => [
    isOpen,
    messages,
    stage,
    assigneeId,
    applicantName,
  ];
}
