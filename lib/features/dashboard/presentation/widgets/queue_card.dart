import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/case_summary_card.dart';
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

    return CaseSummaryCard(
      reference: item.reference,
      title: item.propertyName,
      subtitle: item.partyName,
      status: QueueStatusChip(status: item.status),
      trailing: _DueLabel(dueInDays: item.dueInDays),
      actionLabel: action.label,
      onAction: action.isEnabled ? onPressed : null,
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
