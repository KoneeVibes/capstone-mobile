import 'package:flutter/material.dart';

import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../domain/entities/chat_message.dart';

/// One line in the transcript: avatar, author, and the message beneath.
class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({required this.message, super.key});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final initial = message.authorName.trim().isEmpty
        ? '?'
        : message.authorName.trim()[0].toUpperCase();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppAvatar(
          initials: initial,
          size: AppSizing.avatarSm,
          backgroundColor: message.isMine
              ? AppColors.success
              : AppColors.primary,
        ),
        const SizedBox(width: AppSizing.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message.authorName, style: AppTextStyles.titleSmall),
              const SizedBox(height: AppSizing.space4),
              Text(message.text, style: AppTextStyles.bodyLarge),
              if (!message.isMine) ...[
                const SizedBox(height: AppSizing.space8),
                const _MessageGlyphs(),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// The read-aloud and copy affordances the design shows under a reply. Drawn as
/// part of the mock, not yet wired.
class _MessageGlyphs extends StatelessWidget {
  const _MessageGlyphs();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(
          Icons.volume_up_outlined,
          size: AppSizing.iconSm,
          color: AppColors.textTertiary,
        ),
        SizedBox(width: AppSizing.space16),
        Icon(
          Icons.content_copy_outlined,
          size: AppSizing.iconSm,
          color: AppColors.textTertiary,
        ),
      ],
    );
  }
}
