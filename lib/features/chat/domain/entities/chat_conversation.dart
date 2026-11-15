import 'package:equatable/equatable.dart';

import 'chat_message.dart';
import 'chat_thread.dart';

/// Whether a case conversation is accepting messages. The server only knows
/// open and closed; a closed one nobody has written in was never opened.
enum ChatStatus { notOpened, open, closed }

/// Who a message is from, to the person reading it. The screen words it.
enum ChatAuthor { me, propertyIntel, caseOfficer, applicant }

/// A case conversation as one signed-in user sees it: the server's thread,
/// who is reading, and a message still on its way.
class ChatConversation extends Equatable {
  const ChatConversation({
    required this.thread,
    required this.viewerId,
    required this.viewerIsStaff,
    this.pending,
  });

  final ChatThread thread;
  final String viewerId;
  final bool viewerIsStaff;

  /// The viewer's own message while its send is in flight.
  final ChatMessage? pending;

  ChatStatus get status {
    if (thread.isOpen) return ChatStatus.open;
    return thread.messages.isEmpty ? ChatStatus.notOpened : ChatStatus.closed;
  }

  /// Oldest first, the pending one last.
  List<ChatMessage> get messages => [...thread.messages, ?pending];

  bool get isSending => pending != null;

  /// Typing and sending are only allowed while open.
  bool get canType => thread.isOpen;

  bool get isClosed => status == ChatStatus.closed;

  /// Only the staff member holding the case opens and closes (ADR 0036).
  bool get isAssignee => viewerId == thread.assigneeId;

  /// Opening moves an accepted case to pending-information.
  bool get canOpen =>
      isAssignee && !thread.isOpen && thread.stage == ChatCaseStage.accepted;

  /// Closing puts a pending-information case back where it was.
  bool get canClose =>
      isAssignee && thread.stage == ChatCaseStage.pendingInformation;

  /// A client sees everyone else as Property Intel; staff see the holder as
  /// the case officer and anyone else as the applicant, each by the name the
  /// message carries when it has one.
  ChatAuthor authorOf(ChatMessage message) {
    if (message.senderId == viewerId) return ChatAuthor.me;
    if (!viewerIsStaff) return ChatAuthor.propertyIntel;
    return message.senderId == thread.assigneeId
        ? ChatAuthor.caseOfficer
        : ChatAuthor.applicant;
  }

  /// A fresh read of the thread; a pending message stays.
  ChatConversation withThread(ChatThread thread) => _copy(thread, pending);

  ChatConversation withPending(ChatMessage message) => _copy(thread, message);

  /// The server's copy of the message takes the pending one's place.
  ChatConversation withSent(ChatMessage message) =>
      _copy(thread.withMessage(message), null);

  ChatConversation withoutPending() => _copy(thread, null);

  ChatConversation _copy(ChatThread thread, ChatMessage? pending) =>
      ChatConversation(
        thread: thread,
        viewerId: viewerId,
        viewerIsStaff: viewerIsStaff,
        pending: pending,
      );

  @override
  List<Object?> get props => [thread, viewerId, viewerIsStaff, pending];
}
