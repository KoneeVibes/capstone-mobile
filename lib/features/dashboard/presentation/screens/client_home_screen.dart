import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/error/async_value_x.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../domain/entities/case_overview.dart';
import '../providers/case_overview_provider.dart';
import '../widgets/overview_card.dart';
import '../widgets/recent_searches_section.dart';
import '../widgets/tracking_banner.dart';
import '../widgets/tracking_panel.dart';

/// The client's Home: start a search, see where their cases stand, and pick
/// up a recent lookup.
///
/// Searching and tracking live on the Search tab, so both go there rather than
/// opening a second copy in this branch.
class ClientHomeScreen extends ConsumerWidget {
  const ClientHomeScreen({
    required this.searchPropertyRouteName,
    required this.progressRouteName,
    super.key,
  });

  final String searchPropertyRouteName;

  /// Takes a `trackingId` path parameter.
  final String progressRouteName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(caseOverviewProvider.future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSizing.screenPadding),
            children: [
              TrackingBanner(
                onTap: () => context.goNamed(searchPropertyRouteName),
              ),
              const SizedBox(height: AppSizing.space24),
              const Text('Overview', style: AppTextStyles.titleMedium),
              const SizedBox(height: AppSizing.space12),
              const _Overview(),
              const SizedBox(height: AppSizing.space24),
              RecentSearchesSection(
                onSelected: (search) => context.goNamed(
                  progressRouteName,
                  pathParameters: {'trackingId': search.trackingId},
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Overview extends ConsumerWidget {
  const _Overview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(caseOverviewProvider);
    final value = overview.value;

    if (value != null) return _OverviewGrid(value: value);
    final failure = overview.failure;
    if (failure != null && !overview.isLoading) {
      return TrackingPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Couldn't load your cases.",
              style: AppTextStyles.titleSmall,
            ),
            const SizedBox(height: AppSizing.space4),
            Text(failure.message, style: AppTextStyles.bodySmall),
            const SizedBox(height: AppSizing.space12),
            AppButton(
              label: 'Try again',
              variant: AppButtonVariant.secondary,
              expanded: false,
              onPressed: () => ref.invalidate(caseOverviewProvider),
            ),
          ],
        ),
      );
    }
    return const _Grid(
      children: [
        OverviewCardSkeleton(),
        OverviewCardSkeleton(),
        OverviewCardSkeleton(),
        OverviewCardSkeleton(),
      ],
    );
  }
}

class _OverviewGrid extends StatelessWidget {
  const _OverviewGrid({required this.value});

  final CaseOverview value;

  @override
  Widget build(BuildContext context) {
    return _Grid(
      children: [
        OverviewCard(
          icon: Icons.search,
          tint: AppColors.primaryBright,
          tintSoft: AppColors.primarySoft,
          count: value.total,
          label: 'Total searches',
        ),
        OverviewCard(
          icon: Icons.task_alt,
          tint: AppColors.success,
          tintSoft: AppColors.successSoft,
          count: value.reportsReady,
          label: 'Reports ready',
        ),
        OverviewCard(
          icon: Icons.timelapse,
          tint: AppColors.accent,
          tintSoft: AppColors.accentSoft,
          count: value.inProgress,
          label: 'In progress',
        ),
        OverviewCard(
          icon: Icons.error_outline,
          tint: AppColors.warning,
          tintSoft: AppColors.warningSoft,
          count: value.needsInput,
          label: 'Needs your input',
        ),
      ],
    );
  }
}

/// Two columns of equal-height cards.
class _Grid extends StatelessWidget {
  const _Grid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var row = 0; row < children.length; row += 2) ...[
          if (row > 0) const SizedBox(height: AppSizing.space12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: children[row]),
                const SizedBox(width: AppSizing.space12),
                Expanded(child: children[row + 1]),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
