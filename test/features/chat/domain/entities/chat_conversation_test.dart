import 'package:flutter_test/flutter_test.dart';
import 'package:propertyintelmobileapp/features/chat/domain/entities/chat_conversation.dart';
import 'package:propertyintelmobileapp/features/chat/domain/entities/chat_message.dart';
import 'package:propertyintelmobileapp/features/chat/domain/entities/chat_thread.dart';

import '../../chat_fixtures.dart';

void main() {
  ChatConversation seenBy(
    String viewerId, {
    required ChatThread thread,
    bool isStaff = true,
  }) => ChatConversation(
    thread: thread,
    viewerId: viewerId,
    viewerIsStaff: isStaff,
  );

  test('a closed conversation nobody wrote in was never opened', () {
    final unopened = thread(
      isOpen: false,
      messages: [],
      stage: ChatCaseStage.accepted,
    );

    expect(seenBy(officerId, thread: unopened).status, ChatStatus.notOpened);
    expect(
      seenBy(officerId, thread: thread(isOpen: false)).status,
      ChatStatus.closed,
    );
    expect(seenBy(officerId, thread: thread()).status, ChatStatus.open);
  });

  test('only the holder opens, and only an accepted case', () {
    final accepted = thread(isOpen: false, stage: ChatCaseStage.accepted);

    expect(seenBy(officerId, thread: accepted).canOpen, isTrue);
    expect(seenBy('manager-1', thread: accepted).canOpen, isFalse);
    expect(seenBy(clientId, thread: accepted, isStaff: false).canOpen, isFalse);
    // A disputed or under-review case cannot move to pending-information.
    expect(
      seenBy(
        officerId,
        thread: thread(isOpen: false, stage: ChatCaseStage.other),
      ).canOpen,
      isFalse,
    );
  });

  test('only the holder closes, while it is pending information', () {
    expect(seenBy(officerId, thread: thread()).canClose, isTrue);
    expect(seenBy('manager-1', thread: thread()).canClose, isFalse);
    expect(
      seenBy(clientId, thread: thread(), isStaff: false).canClose,
      isFalse,
    );
    expect(
      seenBy(
        officerId,
        thread: thread(isOpen: false, stage: ChatCaseStage.accepted),
      ).canClose,
      isFalse,
    );
  });

  test('anyone may type while it is open, nobody once it is not', () {
    expect(seenBy(clientId, thread: thread(), isStaff: false).canType, isTrue);
    expect(seenBy('manager-1', thread: thread()).canType, isTrue);
    expect(seenBy(officerId, thread: thread(isOpen: false)).canType, isFalse);
  });

  test('names each sender for whoever is reading', () {
    final client = seenBy(clientId, thread: thread(), isStaff: false);
    expect(client.authorOf(clientMessage), ChatAuthor.me);
    expect(client.authorOf(officerMessage), ChatAuthor.propertyIntel);

    final officer = seenBy(officerId, thread: thread());
    expect(officer.authorOf(officerMessage), ChatAuthor.me);
    expect(officer.authorOf(clientMessage), ChatAuthor.applicant);

    final manager = seenBy('manager-1', thread: thread());
    expect(manager.authorOf(officerMessage), ChatAuthor.caseOfficer);
    expect(manager.authorOf(clientMessage), ChatAuthor.applicant);
  });

  test('a pending message sits last until the sent one replaces it', () {
    const pending = ChatMessage(
      id: 'pending',
      senderId: clientId,
      text: 'On its way',
      isPending: true,
    );
    const sent = ChatMessage(id: 'm-3', senderId: clientId, text: 'On its way');
    final sending = seenBy(
      clientId,
      thread: thread(),
      isStaff: false,
    ).withPending(pending);

    expect(sending.isSending, isTrue);
    expect(sending.messages.last, pending);

    final done = sending.withSent(sent);
    expect(done.isSending, isFalse);
    expect(done.messages, [officerMessage, clientMessage, sent]);
    // A poll may have brought it first.
    expect(done.withSent(sent).messages, hasLength(3));

    expect(sending.withoutPending().messages, hasLength(2));
  });
}
