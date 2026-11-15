import 'package:flutter_test/flutter_test.dart';
import 'package:propertyintelmobileapp/features/chat/data/models/chat_thread_model.dart';
import 'package:propertyintelmobileapp/features/chat/domain/entities/chat_thread.dart';

import '../../chat_fixtures.dart';

void main() {
  test('reads the conversation off a case', () {
    expect(ChatThreadModel.fromData(openCaseJson), thread());
  });

  test('a case with no conversation is closed and empty', () {
    // Live, 15 Nov 2026: cases filed before conversations have no such key.
    final legacy = ChatThreadModel.fromData(const <String, dynamic>{
      'id': 'case-2',
      'assigneeId': officerId,
      'status': 'accepted',
    });

    expect(legacy.isOpen, isFalse);
    expect(legacy.messages, isEmpty);
    expect(legacy.stage, ChatCaseStage.accepted);
    expect(legacy.applicantName, isNull);

    final nulled = ChatThreadModel.fromData(const <String, dynamic>{
      'status': 'closed',
      'conversation': null,
      'assigneeId': null,
    });
    expect(nulled.isOpen, isFalse);
    expect(nulled.stage, ChatCaseStage.other);
    expect(nulled.assigneeId, isNull);
  });

  test('a new case has a closed conversation with an empty chat', () {
    final fresh = ChatThreadModel.fromData(const <String, dynamic>{
      'status': 'submitted',
      'conversation': {'status': 'closed', 'chat': <dynamic>[]},
    });

    expect(fresh.isOpen, isFalse);
    expect(fresh.messages, isEmpty);
  });

  test('reads the message a send returns, which has no sender name', () {
    final sent = ChatThreadModel.sentFromData(const <String, dynamic>{
      'caseId': 'case-1',
      'message': {
        'id': 'm-1',
        'senderId': officerId,
        'text': 'Could you provide the missing property document?',
        'sentAt': '2026-11-15T09:30:00.000Z',
        'updatedAt': '2026-11-15T09:30:00.000Z',
      },
    });

    expect(sent.id, officerMessage.id);
    expect(sent.senderId, officerId);
    expect(sent.sentAt, officerMessage.sentAt);
    expect(sent.senderName, isNull);
  });

  test('refuses a payload that is not a case or a message', () {
    expect(() => ChatThreadModel.fromData(null), throwsFormatException);
    expect(
      () => ChatThreadModel.sentFromData(const <String, dynamic>{}),
      throwsFormatException,
    );
  });

  test('the toggle sends pending-information', () {
    expect(ChatThreadModel.toggleBody, {'status': 'pending-information'});
  });
}
