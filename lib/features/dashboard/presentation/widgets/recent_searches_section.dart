import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/recent_search.dart';
import '../providers/recent_searches_provider.dart';
import 'recent_search_tile.dart';
import 'tracking_panel.dart';

/// "Your recent searches", or a line saying where they will appear.
class RecentSearchesSection extends ConsumerWidget {
  const RecentSearchesSection({required this.onSelected, super.key});

  final ValueChanged<RecentSearch> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searches = ref.watch(recentSearchesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Your recent searches', style: AppTextStyles.titleMedium),
        const SizedBox(height: AppSizing.space12),
        if (searches.isEmpty)
          const _NoRecentSearches()
        else
          for (final search in searches) ...[
            RecentSearchTile(value: search, onTap: () => onSelected(search)),
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
