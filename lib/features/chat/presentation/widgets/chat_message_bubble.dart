import 'package:clock/clock.dart';
import 'package:flutter/material.dart';

import '../../../../core/formatting/app_formatters.dart';
import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../domain/entities/chat_message.dart';

/// One line in the transcript: avatar, author and time, and the message
/// beneath. Greyed while its send is in flight.
class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    required this.message,
    required this.authorName,
    required this.isMine,
    super.key,
  });

  final ChatMessage message;
  final String authorName;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final initial = authorName.trim().isEmpty
        ? '?'
        : authorName.trim()[0].toUpperCase();
    final stamp = message.isPending ? 'Sending…' : _stamp(message.sentAt);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppAvatar(
          initials: initial,
          size: AppSizing.avatarSm,
          backgroundColor: isMine ? AppColors.success : AppColors.primary,
        ),
        const SizedBox(width: AppSizing.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      authorName,
                      style: AppTextStyles.titleSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (stamp.isNotEmpty) ...[
                    const SizedBox(width: AppSizing.space8),
                    Text(stamp, style: AppTextStyles.bodySmall),
                  ],
                ],
              ),
              const SizedBox(height: AppSizing.space4),
              Text(
                message.text,
                style: message.isPending
                    ? AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textTertiary,
                      )
                    : AppTextStyles.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// The time for a message sent today, the date as well for an older one.
  static String _stamp(DateTime? sentAt) {
    if (sentAt == null) return '';
    final local = sentAt.toLocal();
    final now = clock.now();
    final isToday =
        local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    return isToday
        ? AppFormatters.time(sentAt)
        : AppFormatters.dateTime(sentAt);
  }
}
