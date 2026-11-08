import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/error/async_value_x.dart';
import '../../../../shared/widgets/on_tab_return.dart';
import '../../domain/entities/recent_search.dart';
import '../providers/recent_searches_provider.dart';
import 'overview_failure.dart';
import 'recent_search_tile.dart';
import 'tracking_panel.dart';

/// "Your recent searches", re-read whenever its tab comes back into view.
class RecentSearchesSection extends ConsumerStatefulWidget {
  const RecentSearchesSection({required this.onSelected, super.key});

  final ValueChanged<RecentSearch> onSelected;

  @override
  ConsumerState<RecentSearchesSection> createState() =>
      _RecentSearchesSectionState();
}

class _RecentSearchesSectionState extends ConsumerState<RecentSearchesSection>
    with OnTabReturn {
  @override
  void onTabReturn() => ref.invalidate(recentSearchesProvider);

  @override
  Widget build(BuildContext context) {
    final searches = ref.watch(recentSearchesProvider);
    final value = searches.value;
    final failure = searches.failure;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Your recent searches', style: AppTextStyles.titleMedium),
        const SizedBox(height: AppSizing.space12),
        if (value != null && value.isEmpty)
          const _NoRecentSearches()
        else if (value != null)
          for (final search in value) ...[
            RecentSearchTile(
              value: search,
              onTap: () => widget.onSelected(search),
            ),
            const SizedBox(height: AppSizing.space12),
          ]
        else if (failure != null && !searches.isLoading)
          OverviewFailure(
            title: "Couldn't load your recent searches.",
            failure: failure,
            onRetry: () => ref.invalidate(recentSearchesProvider),
          )
        else
          for (var i = 0; i < 2; i++) ...[
            const RecentSearchTileSkeleton(),
            const SizedBox(height: AppSizing.space12),
          ],
      ],
    );
  }
}

class _NoRecentSearches extends StatelessWidget {
  const _NoRecentSearches();

  @override
  Widget build(BuildContext context) {
    return const TrackingPanel(
      child: Row(
        children: [
          Icon(
            Icons.history,
            size: AppSizing.iconMd,
            color: AppColors.textTertiary,
          ),
          SizedBox(width: AppSizing.space12),
          Expanded(
            child: Text(
              'Your recent searches will show up here.',
              style: AppTextStyles.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
