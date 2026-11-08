import 'package:flutter/material.dart';

import '../../../../core/formatting/app_formatters.dart';
import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_shimmer.dart';
import '../../domain/entities/recent_search.dart';
import 'tracking_icon_tile.dart';

class RecentSearchTile extends StatelessWidget {
  const RecentSearchTile({required this.value, required this.onTap, super.key});

  final RecentSearch value;
  final VoidCallback onTap;

  /// `Searched 2 hours ago`, `Searched yesterday`, `Searched 12 Aug`.
  static String searchedLabel(DateTime? searchedAt, {DateTime? now}) {
    final when = AppFormatters.relative(searchedAt, now: now);
    if (when.isEmpty) return '';
    return 'Searched ${when[0].toLowerCase()}${when.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = searchedLabel(value.searchedAt);

    return _TileFrame(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value.trackingId,
            style: AppTextStyles.titleSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: AppSizing.space2),
            Text(subtitle, style: AppTextStyles.bodySmall),
          ],
        ],
      ),
    );
  }
}

class RecentSearchTileSkeleton extends StatelessWidget {
  const RecentSearchTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const _TileFrame(
      child: AppShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppShimmerBox(width: 120, height: AppSizing.space16),
            SizedBox(height: AppSizing.space6),
            AppShimmerBox(width: 100),
          ],
        ),
      ),
    );
  }
}

/// The card and clock tile both states share.
class _TileFrame extends StatelessWidget {
  const _TileFrame({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSizing.radiusLg);

    return Material(
      color: AppColors.surface,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.all(AppSizing.space16),
          child: Row(
            children: [
              const TrackingIconTile(),
              const SizedBox(width: AppSizing.space12),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}
