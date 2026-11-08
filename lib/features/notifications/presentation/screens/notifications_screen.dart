import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/formatting/app_formatters.dart';
import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/error/async_value_x.dart';
import '../../../../shared/widgets/app_state_view.dart';
import '../../domain/entities/app_notification.dart';
import '../providers/notifications_provider.dart';

/// The signed-in user's notifications. Opening it marks them all read.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(notificationsProvider.notifier).markAllRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationsProvider);
    final items = notifications.value;
    final failure = notifications.failure;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.chevron_left),
          onPressed: () => context.pop(),
        ),
        title: const Text('Notifications', style: AppTextStyles.titleMedium),
      ),
      body: items != null
          ? items.isEmpty
                ? const AppStateView.empty(
                    icon: Icons.feedback_outlined,
                    title: 'No Notifications',
                    message:
                        "We'll let you know when there's something to update "
                        'you on.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSizing.screenPadding),
                    itemCount: items.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSizing.space24),
                    itemBuilder: (context, index) =>
                        _NotificationTile(item: items[index]),
                  )
          : failure != null && !notifications.isLoading
          ? AppStateView.failure(
              title: "Couldn't load your notifications.",
              failure: failure,
              onRetry: () => ref.invalidate(notificationsProvider),
            )
          : const AppStateView.loading(),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item});

  final AppNotification item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: AppSizing.iconButtonSize,
          height: AppSizing.iconButtonSize,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(AppSizing.radiusSm),
          ),
          child: Icon(
            switch (item.kind) {
              NotificationKind.assignment => Icons.assignment_ind_outlined,
              NotificationKind.update => Icons.campaign_outlined,
            },
            size: AppSizing.iconMd,
            color: AppColors.primaryBright,
          ),
        ),
        const SizedBox(width: AppSizing.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title, style: AppTextStyles.titleSmall),
              const SizedBox(height: AppSizing.space4),
              Text(
                item.body,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSizing.space8),
        Text(
          AppFormatters.relative(item.createdAt),
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}
