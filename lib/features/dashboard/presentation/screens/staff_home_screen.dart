import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/extensions/context_extensions.dart';
import '../../domain/entities/queue_item.dart';
import '../providers/queue_overview_provider.dart';
import '../widgets/overview_card.dart';
import '../widgets/queue_section.dart';
import '../widgets/staff_greeting_banner.dart';
import '../widgets/tracking_banner.dart';

/// The staff member's home — the Dashboard tab.
///
/// A greeting, the two headline counts, and the work in their queue. The routes
/// its actions open come in from the router, so the screen imports no other
/// feature.
class StaffHomeScreen extends ConsumerWidget {
  const StaffHomeScreen({
    required this.caseDetailRouteName,
    required this.chatRouteName,
    required this.trackingLookupRouteName,
    required this.casesRouteName,
    super.key,
  });

  /// Takes a `caseId` path parameter.
  final String caseDetailRouteName;

  /// Takes a `caseId` path parameter.
  final String chatRouteName;

  final String trackingLookupRouteName;
  final String casesRouteName;

  void _openDetail(BuildContext context, QueueItem item) => context.goNamed(
    caseDetailRouteName,
    pathParameters: {'caseId': item.reference},
  );

  void _openChat(BuildContext context, QueueItem item) => context.pushNamed(
    chatRouteName,
    pathParameters: {'caseId': item.reference},
  );

  // The one confirmed one-click action; no screen to open.
  // TODO(backend): accept the assignment through the real endpoint.
  void _accept(BuildContext context, QueueItem item) =>
      context.showMessage('Assignment accepted');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSizing.screenPadding),
          children: [
            const StaffGreetingBanner(),
            const SizedBox(height: AppSizing.space24),
            const Text('Overview', style: AppTextStyles.titleMedium),
            const SizedBox(height: AppSizing.space12),
            const _Overview(),
            const SizedBox(height: AppSizing.space24),
            // The tracking lookup / property search, as a card between the
            // overview and the queue.
            TrackingBanner(
              showIllustration: false,
              onTap: () => context.pushNamed(trackingLookupRouteName),
            ),
            const SizedBox(height: AppSizing.space24),
            QueueSection(
              onViewAll: () => context.goNamed(casesRouteName),
              onOpenDetail: (item) => _openDetail(context, item),
              onAccept: (item) => _accept(context, item),
              onOpenChat: (item) => _openChat(context, item),
            ),
          ],
        ),
      ),
    );
  }
}

/// The two headline counts, side by side.
class _Overview extends ConsumerWidget {
  const _Overview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(queueOverviewProvider);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: OverviewCard(
              icon: Icons.inbox_outlined,
              tint: AppColors.primaryBright,
              tintSoft: AppColors.primarySoft,
              count: overview.inQueue,
              label: 'searches in your queue',
            ),
          ),
          const SizedBox(width: AppSizing.space12),
          Expanded(
            child: OverviewCard(
              icon: Icons.task_alt,
              tint: AppColors.success,
              tintSoft: AppColors.successSoft,
              count: overview.doneThisWeek,
              label: 'done this week',
            ),
          ),
        ],
      ),
    );
  }
}
