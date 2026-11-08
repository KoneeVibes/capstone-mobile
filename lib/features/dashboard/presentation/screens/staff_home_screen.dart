import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/error/async_value_x.dart';
import '../../../../shared/widgets/on_tab_return.dart';
import '../../domain/entities/queue_overview.dart';
import '../providers/queue_overview_provider.dart';
import '../widgets/home_top_bar.dart';
import '../widgets/overview_card.dart';
import '../widgets/overview_failure.dart';
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
    required this.notificationBell,
    super.key,
  });

  /// "My queue": real cases, with the same buttons as the Cases tab.
  final Widget queue;

  final String trackingLookupRouteName;

  /// The notifications feature's bell, handed in by the router.
  final Widget notificationBell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            HomeTopBar(bell: notificationBell),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.refresh(queueOverviewProvider.future),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
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
            ),
          ],
        ),
      ),
    );
  }
}

/// The two headline counts, re-read whenever the Dashboard tab comes back
/// into view.
class _Overview extends ConsumerStatefulWidget {
  const _Overview();

  @override
  ConsumerState<_Overview> createState() => _OverviewState();
}

class _OverviewState extends ConsumerState<_Overview> with OnTabReturn {
  @override
  void onTabReturn() => ref.invalidate(queueOverviewProvider);

  @override
  Widget build(BuildContext context) {
    final overview = ref.watch(queueOverviewProvider);
    final value = overview.value;

    if (value != null) return _OverviewRow(value: value);
    final failure = overview.failure;
    if (failure != null && !overview.isLoading) {
      return OverviewFailure(
        title: "Couldn't load your cases.",
        failure: failure,
        onRetry: () => ref.invalidate(queueOverviewProvider),
      );
    }
    return const _Row(
      first: OverviewCardSkeleton(),
      second: OverviewCardSkeleton(),
    );
  }
}

class _OverviewRow extends StatelessWidget {
  const _OverviewRow({required this.value});

  final QueueOverview value;

  @override
  Widget build(BuildContext context) {
    return _Row(
      first: OverviewCard(
        icon: Icons.inbox_outlined,
        tint: AppColors.primaryBright,
        tintSoft: AppColors.primarySoft,
        count: value.inQueue,
        label: 'searches in your queue',
      ),
      second: OverviewCard(
        icon: Icons.task_alt,
        tint: AppColors.success,
        tintSoft: AppColors.successSoft,
        count: value.assignedThisWeek,
        label: 'assigned this week',
      ),
    );
  }
}

/// Two equal-height cards side by side.
class _Row extends StatelessWidget {
  const _Row({required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: first),
          const SizedBox(width: AppSizing.space12),
          Expanded(child: second),
        ],
      ),
    );
  }
}
