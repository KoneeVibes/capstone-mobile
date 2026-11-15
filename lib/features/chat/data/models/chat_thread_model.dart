import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_thread.dart';

/// Decodes the conversation out of a case payload, and a sent message.
abstract final class ChatThreadModel {
  /// The body `PATCH /case/{id}` takes to open or close: the same status
  /// toggles both ways.
  static const Map<String, dynamic> toggleBody = {
    'status': 'pending-information',
  };

  /// The `data` object of `GET /case/{id}`. Cases filed before conversations
  /// existed have no `conversation` at all (checked live, 15 Nov 2026); that
  /// reads as closed and empty.
  static ChatThread fromData(Object? data) {
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Expected a case object in "data".');
    }
    final conversation = data['conversation'];
    final chat = conversation is Map ? conversation['chat'] : null;
    return ChatThread(
      isOpen: conversation is Map && conversation['status'] == 'open',
      messages: [
        if (chat is List)
          for (final item in chat)
            if (item is Map<String, dynamic>) messageFromJson(item),
      ],
      stage: switch (data['status']) {
        'accepted' => ChatCaseStage.accepted,
        'pending-information' => ChatCaseStage.pendingInformation,
        _ => ChatCaseStage.other,
      },
      assigneeId: _string(data['assigneeId']),
      applicantName: _string(data['applicantName']),
    );
  }

  /// The `data` object of `POST /case/{id}/message`: `{caseId, message}`.
  static ChatMessage sentFromData(Object? data) {
    final message = data is Map ? data['message'] : null;
    if (message is! Map<String, dynamic>) {
      throw const FormatException('Expected a message object in "data".');
    }
    return messageFromJson(message);
  }

  static ChatMessage messageFromJson(Map<String, dynamic> json) => ChatMessage(
    id: _string(json['id']) ?? _string(json['_id']) ?? '',
    senderId: _string(json['senderId']) ?? '',
    text: _string(json['text']) ?? '',
    senderName: _string(json['senderName']),
    sentAt: DateTime.tryParse(_string(json['sentAt']) ?? ''),
  );

  static String? _string(Object? value) =>
      value is String && value.isNotEmpty ? value : null;
}
