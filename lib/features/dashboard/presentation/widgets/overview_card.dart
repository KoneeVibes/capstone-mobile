import 'package:flutter/material.dart';

import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_shimmer.dart';

/// One count on the client Home: a tinted icon, the number, what it counts.
class OverviewCard extends StatelessWidget {
  const OverviewCard({
    required this.icon,
    required this.tint,
    required this.tintSoft,
    required this.count,
    required this.label,
    super.key,
  });

  final IconData icon;
  final Color tint;
  final Color tintSoft;
  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$count $label',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(AppSizing.space16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: AppSizing.iconButtonSize,
              height: AppSizing.iconButtonSize,
              decoration: BoxDecoration(
                color: tintSoft,
                borderRadius: BorderRadius.circular(AppSizing.radiusMd),
              ),
              child: Icon(icon, size: AppSizing.iconMd, color: tint),
            ),
            const SizedBox(height: AppSizing.space12),
            Text('$count', style: AppTextStyles.displayLarge),
            const SizedBox(height: AppSizing.space2),
            Text(
              label,
              style: AppTextStyles.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// [OverviewCard]'s shape while the counts load.
class OverviewCardSkeleton extends StatelessWidget {
  const OverviewCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizing.space16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
      ),
      child: const AppShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppShimmerBox.square(size: AppSizing.iconButtonSize),
            SizedBox(height: AppSizing.space12),
            AppShimmerBox(width: AppSizing.space32, height: AppSizing.space32),
            SizedBox(height: AppSizing.space4),
            AppShimmerBox(
              width: AppSizing.space48 * 2,
              height: AppSizing.space12,
            ),
          ],
        ),
      ),
    );
  }
}
