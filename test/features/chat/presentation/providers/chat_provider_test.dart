import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:propertyintelmobileapp/core/navigation/app_session.dart';
import 'package:propertyintelmobileapp/core/session/cases_changed.dart';
import 'package:propertyintelmobileapp/core/utils/error/app_failure.dart';
import 'package:propertyintelmobileapp/core/utils/error/failure_type.dart';
import 'package:propertyintelmobileapp/core/utils/result.dart';
import 'package:propertyintelmobileapp/features/chat/domain/entities/chat_conversation.dart';
import 'package:propertyintelmobileapp/features/chat/domain/entities/chat_message.dart';
import 'package:propertyintelmobileapp/features/chat/domain/entities/chat_thread.dart';
import 'package:propertyintelmobileapp/features/chat/domain/repositories/chat_repository.dart';
import 'package:propertyintelmobileapp/features/chat/presentation/providers/chat_provider.dart';
import 'package:propertyintelmobileapp/features/chat/presentation/providers/chat_providers.dart';

import '../../chat_fixtures.dart';

class MockChatRepository extends Mock implements ChatRepository {}

const _caseId = 'case-1';
const _offline = AppFailure(type: FailureType.network, message: 'Offline');
const _closed = AppFailure(
  type: FailureType.conflict,
  message: 'The conversation is closed.',
);
const _reply = ChatMessage(id: 'm-3', senderId: officerId, text: 'Thanks.');

void main() {
  late MockChatRepository repository;
  final provider = chatProvider(_caseId);

  setUp(() => repository = MockChatRepository());

  void serve(ChatThread value) => when(
    () => repository.fetchThread(_caseId),
  ).thenAnswer((_) async => Ok(value));

  int reads() => verify(() => repository.fetchThread(_caseId)).callCount;

  /// The chat screen, open: a container with a listener, as [viewer].
  ProviderContainer open(FakeAsync async, {SessionUser? viewer}) {
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        chatRepositoryProvider.overrideWithValue(repository),
        sessionProvider.overrideWithValue(
          viewer ?? const SessionUser(id: clientId, role: AppRole.client),
        ),
      ],
    )..listen(provider, (_, _) {});
    async.flushMicrotasks();
    return container;
  }

  const officer = SessionUser(id: officerId, role: AppRole.staff);

  ChatConversation read(ProviderContainer container) =>
      container.read(provider).requireValue;

  test('fetches nothing while signed out', () {
    fakeAsync((async) {
      final container = ProviderContainer(
        overrides: [chatRepositoryProvider.overrideWithValue(repository)],
      )..listen(provider, (_, _) {});
      async.elapse(const Duration(minutes: 1));

      expect(container.read(provider).isLoading, isTrue);
      verifyNever(() => repository.fetchThread(any()));
      container.dispose();
    });
  });

  test('loads the conversation for whoever is signed in', () {
    fakeAsync((async) {
      serve(thread());
      final container = open(async);

      final conversation = read(container);
      expect(conversation.thread, thread());
      expect(conversation.viewerId, clientId);
      expect(conversation.viewerIsStaff, isFalse);
      container.dispose();
    });
  });

  test('a failed first load is an error, and nothing polls', () {
    fakeAsync((async) {
      when(
        () => repository.fetchThread(_caseId),
      ).thenAnswer((_) async => const Err(_offline));
      final container = open(async);

      async.elapse(const Duration(minutes: 5));

      expect(container.read(provider).hasError, isTrue);
      expect(reads(), 1);
      container.dispose();
    });
  });

  group('polling', () {
    test('re-reads every 4s, slowing while nothing changes', () {
      fakeAsync((async) {
        serve(thread());
        final container = open(async);
        expect(reads(), 1);

        // Three reads at 4s, then the 8s step.
        async.elapse(const Duration(seconds: 12));
        expect(reads(), 3);
        async.elapse(const Duration(seconds: 7));
        verifyNever(() => repository.fetchThread(_caseId));
        async.elapse(const Duration(seconds: 1));
        expect(reads(), 1);
        container.dispose();
      });
    });

    test('a new message shows up and speeds it back up', () {
      fakeAsync((async) {
        serve(thread());
        final container = open(async);
        async.elapse(const Duration(seconds: 12));
        clearInteractions(repository);

        serve(thread(messages: [officerMessage, clientMessage, _reply]));
        async.elapse(const Duration(seconds: 8));
        expect(read(container).messages.last, _reply);

        clearInteractions(repository);
        async.elapse(const Duration(seconds: 4));
        expect(reads(), 1);
        container.dispose();
      });
    });

    test('an unchanged read does not notify the screen', () {
      fakeAsync((async) {
        serve(thread());
        final container = open(async);
        var notified = 0;
        container.listen(provider, (_, _) => notified++);

        async.elapse(const Duration(minutes: 2));

        expect(notified, 0);
        container.dispose();
      });
    });

    test('a closed conversation is checked every 30s', () {
      fakeAsync((async) {
        serve(thread(isOpen: false));
        final container = open(async);
        clearInteractions(repository);

        async.elapse(const Duration(seconds: 29));
        verifyNever(() => repository.fetchThread(_caseId));
        async.elapse(const Duration(seconds: 1));
        expect(reads(), 1);
        container.dispose();
      });
    });

    test('a failed read keeps the transcript and waits longer', () {
      fakeAsync((async) {
        serve(thread());
        final container = open(async);
        clearInteractions(repository);

        when(
          () => repository.fetchThread(_caseId),
        ).thenAnswer((_) async => const Err(_offline));
        async.elapse(const Duration(seconds: 4));
        expect(reads(), 1);
        expect(read(container).thread, thread());

        // 8s after the first failure, 16s after the second.
        async.elapse(const Duration(seconds: 7));
        verifyNever(() => repository.fetchThread(_caseId));
        async.elapse(const Duration(seconds: 1));
        expect(reads(), 1);
        async.elapse(const Duration(seconds: 15));
        verifyNever(() => repository.fetchThread(_caseId));
        container.dispose();
      });
    });

    test('stops while the app is hidden; catches up on return', () {
      fakeAsync((async) {
        serve(thread());
        final container = open(async);
        clearInteractions(repository);

        container.read(provider.notifier).pause();
        async.elapse(const Duration(minutes: 10));
        verifyNever(() => repository.fetchThread(_caseId));

        serve(thread(messages: [officerMessage, clientMessage, _reply]));
        container.read(provider.notifier).resume();
        async.flushMicrotasks();
        expect(reads(), 1);
        expect(read(container).messages.last, _reply);

        async.elapse(const Duration(seconds: 4));
        expect(reads(), 1);
        container.dispose();
      });
    });

    test('stops when the screen is left', () {
      fakeAsync((async) {
        serve(thread());
        final container = open(async)..dispose();
        clearInteractions(repository);

        async.elapse(const Duration(minutes: 10));

        verifyNever(() => repository.fetchThread(_caseId));
        expect(async.pendingTimers, isEmpty);
        container.dispose();
      });
    });
  });

  group('sending', () {
    test('shows the message at once, then the server copy', () {
      fakeAsync((async) {
        serve(thread());
        final container = open(async);
        final sent = Completer<Result<ChatMessage>>();
        when(
          () => repository.sendMessage(_caseId, 'On its way'),
        ).thenAnswer((_) => sent.future);

        unawaited(container.read(provider.notifier).send('  On its way  '));
        async.flushMicrotasks();

        final pending = read(container).messages.last;
        expect(pending.isPending, isTrue);
        expect(pending.text, 'On its way');
        expect(pending.senderId, clientId);

        const stored = ChatMessage(
          id: 'm-3',
          senderId: clientId,
          text: 'On its way',
        );
        sent.complete(const Ok(stored));
        async.flushMicrotasks();

        expect(read(container).isSending, isFalse);
        expect(read(container).messages.last, stored);
        container.dispose();
      });
    });

    test('a read that started before the send cannot undo it', () {
      fakeAsync((async) {
        serve(thread());
        final container = open(async);
        // A slow poll is in the air when the user sends.
        final slowRead = Completer<Result<ChatThread>>();
        when(
          () => repository.fetchThread(_caseId),
        ).thenAnswer((_) => slowRead.future);
        async.elapse(const Duration(seconds: 4));

        const stored = ChatMessage(id: 'm-3', senderId: clientId, text: 'Hi');
        when(
          () => repository.sendMessage(_caseId, 'Hi'),
        ).thenAnswer((_) async => const Ok(stored));
        unawaited(container.read(provider.notifier).send('Hi'));
        async.flushMicrotasks();

        slowRead.complete(Ok(thread()));
        async.flushMicrotasks();

        expect(read(container).messages.last, stored);
        container.dispose();
      });
    });

    test('a failure takes the message back out', () {
      fakeAsync((async) {
        serve(thread());
        final container = open(async);
        when(
          () => repository.sendMessage(_caseId, 'Hi'),
        ).thenAnswer((_) async => const Err(_offline));

        Result<void>? result;
        unawaited(
          container
              .read(provider.notifier)
              .send('Hi')
              .then((value) => result = value),
        );
        async.flushMicrotasks();

        expect(result?.failureOrNull, _offline);
        expect(read(container).messages, [officerMessage, clientMessage]);
        container.dispose();
      });
    });

    test('a conflict re-reads at once: it was closed meanwhile', () {
      fakeAsync((async) {
        serve(thread());
        final container = open(async);
        clearInteractions(repository);
        when(
          () => repository.sendMessage(_caseId, 'Hi'),
        ).thenAnswer((_) async => const Err(_closed));
        serve(thread(isOpen: false, stage: ChatCaseStage.accepted));

        unawaited(container.read(provider.notifier).send('Hi'));
        async.flushMicrotasks();

        expect(reads(), 1);
        expect(read(container).canType, isFalse);
        container.dispose();
      });
    });

    test('sends nothing blank, twice at once, or while closed', () {
      fakeAsync((async) {
        serve(thread());
        final container = open(async);
        final notifier = container.read(provider.notifier);
        when(
          () => repository.sendMessage(_caseId, any()),
        ).thenAnswer((_) => Completer<Result<ChatMessage>>().future);

        unawaited(notifier.send('   '));
        unawaited(notifier.send('first'));
        unawaited(notifier.send('second'));
        async.flushMicrotasks();

        verify(() => repository.sendMessage(_caseId, 'first')).called(1);
        verifyNever(() => repository.sendMessage(_caseId, 'second'));
        container.dispose();
      });

      fakeAsync((async) {
        serve(thread(isOpen: false));
        final container = open(async);

        unawaited(container.read(provider.notifier).send('Hi'));
        async.flushMicrotasks();

        verifyNever(() => repository.sendMessage(any(), any()));
        container.dispose();
      });
    });
  });

  group('opening and closing', () {
    test('the holder opens it; the case screens are told', () {
      fakeAsync((async) {
        serve(
          thread(isOpen: false, messages: [], stage: ChatCaseStage.accepted),
        );
        final container = open(async, viewer: officer);
        expect(read(container).canOpen, isTrue);
        final before = container.read(casesChangedProvider);

        when(
          () => repository.toggleConversation(_caseId),
        ).thenAnswer((_) async => const Ok(null));
        serve(thread(messages: []));
        unawaited(container.read(provider.notifier).toggle());
        async.flushMicrotasks();

        expect(read(container).status, ChatStatus.open);
        expect(read(container).canClose, isTrue);
        expect(container.read(casesChangedProvider), before + 1);
        container.dispose();
      });
    });

    test('a refusal re-reads and leaves the case screens alone', () {
      fakeAsync((async) {
        serve(thread());
        final container = open(async, viewer: officer);
        clearInteractions(repository);
        final before = container.read(casesChangedProvider);
        when(
          () => repository.toggleConversation(_caseId),
        ).thenAnswer((_) async => const Err(_closed));

        Result<void>? result;
        unawaited(
          container
              .read(provider.notifier)
              .toggle()
              .then((value) => result = value),
        );
        async.flushMicrotasks();

        expect(result?.isErr, isTrue);
        expect(reads(), 1);
        expect(container.read(casesChangedProvider), before);
        container.dispose();
      });
    });

    test('anyone else cannot toggle', () {
      fakeAsync((async) {
        serve(thread());
        final container = open(async);

        unawaited(container.read(provider.notifier).toggle());
        async.flushMicrotasks();

        verifyNever(() => repository.toggleConversation(any()));
        container.dispose();
      });
    });
  });
}
