import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/chat_conversation.dart';
import '../../domain/entities/chat_message.dart';

/// One case conversation, keyed by case id.
///
/// Mock: the transcript is seeded in memory and messages are appended locally.
/// Opening and closing only flip the state — there is no transport yet.
///
/// TODO(backend): back this with a real conversation endpoint (load history,
/// send, and the open/close transitions).
class ChatNotifier extends Notifier<ChatConversation> {
  ChatNotifier(this.caseId);

  final String caseId;

  @override
  ChatConversation build() {
    return const ChatConversation(
      status: ChatStatus.notOpened,
      messages: _seed,
    );
  }

  /// Open the conversation so messages can be sent.
  void open() {
    if (state.status == ChatStatus.open) return;
    state = state.copyWith(status: ChatStatus.open);
  }

  /// Close the conversation once it has reached its conclusion.
  void close() {
    if (state.status != ChatStatus.open) return;
    state = state.copyWith(status: ChatStatus.closed);
  }

  /// Append a message. Ignored unless the conversation is open and the text is
  /// not blank.
  void send(String text) {
    final trimmed = text.trim();
    if (state.status != ChatStatus.open || trimmed.isEmpty) return;

    state = state.copyWith(
      messages: [
        ...state.messages,
        ChatMessage(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          authorName: 'You',
          text: trimmed,
          isMine: true,
        ),
      ],
    );
  }

  /// Placeholder transcript, matching the design's demo content.
  static const _seed = [
    ChatMessage(
      id: 'seed-1',
      authorName: 'You',
      text: 'Explain quantum computing in simple terms.',
      isMine: true,
    ),
    ChatMessage(
      id: 'seed-2',
      authorName: 'Ekong Inyene',
      text:
          'Quantum computing is a type of computing where information is '
          'processed using quantum-mechanical phenomena, such as superposition '
          'and entanglement. In traditional computing, information is processed '
          'using bits, which can have a value of either 0 or 1. In quantum '
          'computing, information is processed using quantum bits, or qubits, '
          'which can exist in multiple states simultaneously.',
      isMine: false,
    ),
  ];
}

final chatProvider =
    NotifierProvider.family<ChatNotifier, ChatConversation, String>(
      ChatNotifier.new,
    );
