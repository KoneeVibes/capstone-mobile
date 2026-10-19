import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propertyintelmobileapp/features/chat/domain/entities/chat_conversation.dart';
import 'package:propertyintelmobileapp/features/chat/presentation/providers/chat_provider.dart';

void main() {
  const caseId = 'SLP-2292';

  late ProviderContainer container;
  late ChatNotifier notifier;

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
    notifier = container.read(chatProvider(caseId).notifier);
  });

  ChatConversation read() => container.read(chatProvider(caseId));

  test('starts not opened, with the seeded transcript', () {
    expect(read().status, ChatStatus.notOpened);
    expect(read().messages, isNotEmpty);
    expect(read().canType, isFalse);
    expect(read().canOpen, isTrue);
    expect(read().canClose, isFalse);
  });

  test('sending before opening is ignored', () {
    final before = read().messages.length;
    notifier.send('too early');
    expect(read().messages, hasLength(before));
  });

  test('opening lets a message through and appends it as mine', () {
    final before = read().messages.length;
    notifier.open();

    expect(read().status, ChatStatus.open);
    expect(read().canType, isTrue);
    expect(read().canClose, isTrue);

    notifier.send('  hello  ');
    expect(read().messages, hasLength(before + 1));
    expect(read().messages.last.text, 'hello');
    expect(read().messages.last.isMine, isTrue);
  });

  test('blank messages are not appended', () {
    notifier.open();
    final before = read().messages.length;
    notifier.send('   ');
    expect(read().messages, hasLength(before));
  });

  test('closing stops further messages and flips the state', () {
    notifier.open();
    notifier.send('one');
    final after = read().messages.length;

    notifier.close();
    expect(read().status, ChatStatus.closed);
    expect(read().isClosed, isTrue);
    expect(read().canType, isFalse);
    expect(read().canOpen, isTrue);
    expect(read().canClose, isFalse);

    notifier.send('after close');
    expect(read().messages, hasLength(after));
  });

  test('close does nothing unless the conversation is open', () {
    notifier.close();
    expect(read().status, ChatStatus.notOpened);
  });
}
