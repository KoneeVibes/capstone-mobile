import 'package:propertyintelmobileapp/features/chat/domain/entities/chat_message.dart';
import 'package:propertyintelmobileapp/features/chat/domain/entities/chat_thread.dart';

const officerId = 'staff-1';
const clientId = 'client-1';

/// A case payload with an open conversation, as read live on 15 Nov 2026
/// (`senderName` is not in the spec). Trimmed to what chat reads, plus noise.
const openCaseJson = <String, dynamic>{
  'id': 'case-1',
  'trackingId': 'PI-TEST0001',
  'assigneeId': officerId,
  'applicantName': 'Ada Okafor',
  'status': 'pending-information',
  'conversation': {
    'status': 'open',
    'chat': [
      {
        'id': 'm-1',
        'senderId': officerId,
        'text': 'Could you provide the missing property document?',
        'sentAt': '2026-11-15T09:30:00.000Z',
        'updatedAt': '2026-11-15T09:30:00.000Z',
        'senderName': 'Ada Okafor Regular',
      },
      {
        'id': 'm-2',
        'senderId': clientId,
        'text': 'Sending it now.',
        'sentAt': '2026-11-15T09:31:00.000Z',
        'updatedAt': '2026-11-15T09:31:00.000Z',
        'senderName': 'Ada Okafor',
      },
    ],
  },
};

final officerMessage = ChatMessage(
  id: 'm-1',
  senderId: officerId,
  text: 'Could you provide the missing property document?',
  senderName: 'Ada Okafor Regular',
  sentAt: DateTime.utc(2026, 11, 15, 9, 30),
);

final clientMessage = ChatMessage(
  id: 'm-2',
  senderId: clientId,
  text: 'Sending it now.',
  senderName: 'Ada Okafor',
  sentAt: DateTime.utc(2026, 11, 15, 9, 31),
);

ChatThread thread({
  bool isOpen = true,
  List<ChatMessage>? messages,
  ChatCaseStage stage = ChatCaseStage.pendingInformation,
  String? assigneeId = officerId,
}) => ChatThread(
  isOpen: isOpen,
  messages: messages ?? [officerMessage, clientMessage],
  stage: stage,
  assigneeId: assigneeId,
  applicantName: 'Ada Okafor',
);
