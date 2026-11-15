import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/error/async_value_x.dart';
import '../../../../core/utils/result.dart';
import '../../../../shared/extensions/context_extensions.dart';
import '../../../../shared/widgets/app_shimmer.dart';
import '../../../../shared/widgets/app_state_view.dart';
import '../../domain/entities/chat_conversation.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_closed_banner.dart';
import '../widgets/chat_composer.dart';
import '../widgets/chat_conversation_controls.dart';
import '../widgets/chat_message_bubble.dart';

/// A case conversation, re-read while this screen is in view (ADR 0036).
///
/// Reached from the staff queue and from case detail. Anyone on the case may
/// write while it is open; only the staff member holding it opens and closes.
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
  late final AppLifecycleListener _lifecycle;
  bool _toggling = false;

  String get _display => (widget.reference?.isNotEmpty ?? false)
      ? widget.reference!
      : widget.caseId;

  ChatNotifier get _notifier => ref.read(chatProvider(widget.caseId).notifier);

  @override
  void initState() {
    super.initState();
    // Nothing is fetched while the app is out of view.
    _lifecycle = AppLifecycleListener(
      onHide: () => _notifier.pause(),
      onShow: () => _notifier.resume(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _toggle({required bool opening}) async {
    setState(() => _toggling = true);
    final result = await _notifier.toggle();
    if (!mounted) return;
    setState(() => _toggling = false);

    switch (result) {
      case Ok():
        if (!opening) context.hideKeyboard();
        context.showMessage(
          opening ? 'Conversation opened' : 'Conversation closed',
        );
      case Err(:final failure):
        context.showFailure(failure);
    }
  }

  Future<void> _send() async {
    final text = _controller.text;
    final sending =
        ref.read(chatProvider(widget.caseId)).value?.isSending ?? true;
    if (text.trim().isEmpty || sending) return;
    _controller.clear();
    // The list is reversed, so its start is the newest message.
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.minScrollExtent);
    }

    final result = await _notifier.send(text);
    if (!mounted) return;
    if (result case Err(:final failure)) {
      // Hand the words back, unless the user has started on something else.
      if (_controller.text.isEmpty) _controller.text = text;
      context.showFailure(failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(chatProvider(widget.caseId));
    final conversation = chat.value;
    final failure = chat.failure;

    return Scaffold(
      appBar: AppBar(
        title: Text('Case $_display', style: AppTextStyles.titleMedium),
      ),
      body: SafeArea(
        child: conversation != null
            ? _conversation(conversation)
            : failure != null && !chat.isLoading
            ? AppStateView.failure(
                failure: failure,
                title: "Couldn't load this conversation",
                onRetry: failure.isRetryable
                    ? () => ref.invalidate(chatProvider(widget.caseId))
                    : null,
              )
            : const _ChatSkeleton(),
      ),
    );
  }

  Widget _conversation(ChatConversation conversation) {
    final messages = conversation.messages;

    return Column(
      children: [
        Expanded(
          child: messages.isEmpty
              ? AppStateView.empty(
                  icon: Icons.chat_bubble_outline,
                  title: 'No messages yet',
                  message: _emptyMessage(conversation),
                )
              // Reversed: it opens on the newest message and stays there as
              // more arrive, unless the reader has scrolled up.
              : ListView.separated(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(AppSizing.screenPadding),
                  itemCount: messages.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSizing.space24),
                  itemBuilder: (context, index) {
                    final message = messages[messages.length - 1 - index];
                    final author = conversation.authorOf(message);
                    return ChatMessageBubble(
                      key: ValueKey(message.id),
                      message: message,
                      authorName: _authorName(
                        author,
                        message.senderName,
                        conversation.thread.applicantName,
                      ),
                      isMine: author == ChatAuthor.me,
                    );
                  },
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
                canSend: !conversation.isSending,
                hint: conversation.canType ? 'Message' : 'Chat is not open',
                onSend: _send,
              ),
              if (conversation.isAssignee) ...[
                const SizedBox(height: AppSizing.space12),
                ChatConversationControls(
                  canOpen: conversation.canOpen,
                  canClose: conversation.canClose,
                  busy: _toggling,
                  onOpen: () => _toggle(opening: true),
                  onClose: () => _toggle(opening: false),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Staff see the name the message carries; a client sees the company.
  static String _authorName(
    ChatAuthor author,
    String? senderName,
    String? applicantName,
  ) => switch (author) {
    ChatAuthor.me => 'You',
    ChatAuthor.propertyIntel => 'Property Intel',
    ChatAuthor.caseOfficer => senderName ?? 'Case officer',
    ChatAuthor.applicant => senderName ?? applicantName ?? 'Applicant',
  };

  static String _emptyMessage(ChatConversation conversation) {
    if (conversation.canType) return 'Send the first message.';
    if (conversation.canOpen) {
      return 'Open the chat to ask the applicant for more information.';
    }
    return conversation.viewerIsStaff
        ? 'Only the staff member holding this case can open the chat.'
        : 'Your case officer will open this chat if they need more '
              'information from you.';
  }
}

/// The transcript's shape while it loads: avatar, name, two lines.
class _ChatSkeleton extends StatelessWidget {
  const _ChatSkeleton();

  static const _rows = 4;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSizing.screenPadding),
        itemCount: _rows,
        separatorBuilder: (_, _) => const SizedBox(height: AppSizing.space24),
        itemBuilder: (_, _) => const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppShimmerBox(
              width: AppSizing.avatarSm,
              height: AppSizing.avatarSm,
              shape: BoxShape.circle,
            ),
            SizedBox(width: AppSizing.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppShimmerBox(width: AppSizing.space48 * 2),
                  SizedBox(height: AppSizing.space8),
                  AppShimmerBox(),
                  SizedBox(height: AppSizing.space8),
                  AppShimmerBox(width: AppSizing.space48 * 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
