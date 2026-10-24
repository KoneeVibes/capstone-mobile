import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/queue_overview_provider.dart';
import '../widgets/overview_card.dart';
import '../widgets/staff_greeting_banner.dart';
import '../widgets/tracking_banner.dart';

/// The staff member's home — the Dashboard tab.
///
/// A greeting, the two headline counts, and the work in their queue. The queue
/// is the cases feature's own section, handed in by the router (ADR 0019), so
/// the screen imports no other feature.
class StaffHomeScreen extends ConsumerWidget {
  const StaffHomeScreen({
    required this.queue,
    required this.trackingLookupRouteName,
    super.key,
  });

  /// "My queue": real cases, with the same buttons as the Cases tab.
  final Widget queue;

  final String trackingLookupRouteName;

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
            queue,
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
