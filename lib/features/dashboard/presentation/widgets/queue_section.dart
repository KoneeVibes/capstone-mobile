import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_chip.dart';
import '../../domain/entities/queue_filter.dart';
import '../../domain/entities/queue_item.dart';
import '../providers/staff_queue_provider.dart';
import 'queue_card.dart';

/// The "My queue" block: the heading and its "View all" link, the filter tabs,
/// and the cards for whichever tab is open.
class QueueSection extends ConsumerStatefulWidget {
  const QueueSection({
    required this.onViewAll,
    required this.onOpenDetail,
    required this.onAccept,
    required this.onOpenChat,
    super.key,
  });

  final VoidCallback onViewAll;
  final ValueChanged<QueueItem> onOpenDetail;
  final ValueChanged<QueueItem> onAccept;
  final ValueChanged<QueueItem> onOpenChat;

  @override
  ConsumerState<QueueSection> createState() => _QueueSectionState();
}

class _QueueSectionState extends ConsumerState<QueueSection> {
  QueueFilter _filter = QueueFilter.all;

  @override
  Widget build(BuildContext context) {
    final items = ref
        .watch(staffQueueProvider)
        .where((item) => _filter.matches(item.status))
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('My queue', style: AppTextStyles.titleMedium),
            ),
            GestureDetector(
              onTap: widget.onViewAll,
              behavior: HitTestBehavior.opaque,
              child: const Text('View all', style: AppTextStyles.link),
            ),
          ],
        ),
        const SizedBox(height: AppSizing.space12),
        Wrap(
          spacing: AppSizing.space8,
          runSpacing: AppSizing.space8,
          children: [
            for (final filter in QueueFilter.values)
              AppChoiceChip(
                label: filter.label,
                isSelected: filter == _filter,
                style: AppChoiceChipStyle.neutral,
                onSelected: () => setState(() => _filter = filter),
              ),
          ],
        ),
        const SizedBox(height: AppSizing.space16),
        if (items.isEmpty)
          const _Empty()
        else
          for (final (index, item) in items.indexed) ...[
            if (index != 0) const SizedBox(height: AppSizing.space12),
            QueueCard(
              item: item,
              onOpenDetail: () => widget.onOpenDetail(item),
              onAccept: () => widget.onAccept(item),
              onOpenChat: () => widget.onOpenChat(item),
            ),
          ],
      ],
    );
  }
}

/// When a tab has nothing under it.
class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSizing.space32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
      ),
      child: const Text(
        'Nothing in this tab.',
        style: AppTextStyles.bodyMedium,
        textAlign: TextAlign.center,
      ),
    );
  }
}
