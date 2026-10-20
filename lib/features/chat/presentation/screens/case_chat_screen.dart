import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/extensions/context_extensions.dart';
import '../../domain/entities/chat_conversation.dart';
import '../../domain/entities/chat_message.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_closed_banner.dart';
import '../widgets/chat_composer.dart';
import '../widgets/chat_conversation_controls.dart';
import '../widgets/chat_message_bubble.dart';

/// A case conversation.
///
/// Mock UI: the transcript is seeded and the open/close flow only flips state
/// and raises a snackbar. Reached from the staff queue and from case detail.
class CaseChatScreen extends ConsumerStatefulWidget {
  const CaseChatScreen({required this.caseId, this.reference, super.key});

  final String caseId;

  /// A nicer label than the raw id when the caller has one (a tracking id).
  final String? reference;

  @override
  ConsumerState<CaseChatScreen> createState() => _CaseChatScreenState();
}

class _CaseChatScreenState extends ConsumerState<CaseChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  String get _display => (widget.reference?.isNotEmpty ?? false)
      ? widget.reference!
      : widget.caseId;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _open() {
    ref.read(chatProvider(widget.caseId).notifier).open();
    context.showMessage('Conversation opened');
  }

  void _close() {
    ref.read(chatProvider(widget.caseId).notifier).close();
    context.hideKeyboard();
    context.showMessage('Conversation closed');
  }

  void _send() {
    ref.read(chatProvider(widget.caseId).notifier).send(_controller.text);
    _controller.clear();
    // Let the new line lay out, then bring it into view.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final conversation = ref.watch(chatProvider(widget.caseId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Case $_display', style: AppTextStyles.titleMedium),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.all(AppSizing.screenPadding),
                itemCount: conversation.messages.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSizing.space24),
                itemBuilder: (context, index) =>
                    ChatMessageBubble(message: conversation.messages[index]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizing.screenPadding,
                AppSizing.space8,
                AppSizing.screenPadding,
                AppSizing.space16,
              ),
              child: Column(
                children: [
                  if (conversation.isClosed) ...[
                    ChatClosedBanner(reference: _display),
                    const SizedBox(height: AppSizing.space12),
                  ],
                  ChatComposer(
                    controller: _controller,
                    enabled: conversation.canType,
                    hint: _hint(conversation),
                    onSend: _send,
                  ),
                  const SizedBox(height: AppSizing.space12),
                  ChatConversationControls(
                    canOpen: conversation.canOpen,
                    canClose: conversation.canClose,
                    onOpen: _open,
                    onClose: _close,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The composer hint, naming the other party from the first reply.
  static String _hint(ChatConversation conversation) {
    final other = conversation.messages.cast<ChatMessage?>().firstWhere(
      (m) => m != null && !m.isMine,
      orElse: () => null,
    );
    final name = other?.authorName.trim().split(' ').first ?? '';
    return name.isEmpty ? 'Message' : 'Message $name';
  }
}
