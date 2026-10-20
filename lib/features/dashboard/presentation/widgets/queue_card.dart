import 'package:flutter/material.dart';

import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../domain/entities/queue_item.dart';
import '../../domain/queue_action.dart';
import 'queue_status_chip.dart';

/// One card in the staff queue: reference and status, the property and the
/// person, how long is left, and the single action the status allows.
class QueueCard extends StatelessWidget {
  const QueueCard({
    required this.item,
    required this.onOpenDetail,
    required this.onAccept,
    required this.onOpenChat,
    super.key,
  });

  final QueueItem item;

  /// Open the case detail screen — where all but two actions are carried out.
  final VoidCallback onOpenDetail;

  /// Accept the handed-off case in place: the only confirmed one-click action.
  final VoidCallback onAccept;

  /// Open the case conversation.
  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context) {
    final action = actionFor(item.status);
    final onPressed = switch (action.kind) {
      QueueActionKind.detail => onOpenDetail,
      QueueActionKind.accept => onAccept,
      QueueActionKind.chat => onOpenChat,
    };

    return Container(
      padding: const EdgeInsets.all(AppSizing.space16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Thumbnail(),
              const SizedBox(width: AppSizing.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.reference,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primaryBright,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSizing.space8),
                        QueueStatusChip(status: item.status),
                      ],
                    ),
                    const SizedBox(height: AppSizing.space4),
                    Text(
                      item.propertyName,
                      style: AppTextStyles.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSizing.space4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            item.partyName,
                            style: AppTextStyles.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSizing.space8),
                        _DueLabel(dueInDays: item.dueInDays),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizing.space12),
          AppButton(
            label: action.label,
            variant: AppButtonVariant.soft,
            onPressed: action.isEnabled ? onPressed : null,
          ),
        ],
      ),
    );
  }
}

/// Property thumbnail stand-in.
///
/// TODO(backend): show the property image once the queue endpoint carries one.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizing.iconButtonSize,
      height: AppSizing.iconButtonSize,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
      ),
      child: const Icon(
        Icons.location_city_outlined,
        size: AppSizing.iconMd,
        color: AppColors.primary,
      ),
    );
  }
}

/// How long is left, red once it is overdue.
class _DueLabel extends StatelessWidget {
  const _DueLabel({required this.dueInDays});

  final int dueInDays;

  @override
  Widget build(BuildContext context) {
    final overdue = dueInDays < 0;
    return Text(
      _label(dueInDays),
      style: AppTextStyles.bodySmall.copyWith(
        color: overdue ? AppColors.destructive : AppColors.textSecondary,
        fontWeight: overdue ? FontWeight.w600 : FontWeight.w400,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  static String _label(int days) {
    if (days < 0) {
      final late = -days;
      return 'Overdue · $late ${late == 1 ? 'day' : 'days'}';
    }
    return switch (days) {
      0 => 'Due today',
      1 => 'Due tomorrow',
      _ => 'Due in $days days',
    };
  }
}
