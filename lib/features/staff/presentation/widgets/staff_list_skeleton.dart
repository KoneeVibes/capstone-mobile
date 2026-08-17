import 'package:flutter/material.dart';

import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_shimmer.dart';

/// Placeholder rows shown while the staff list loads for the first time.
///
/// Deliberately mirrors [StaffListTile]'s geometry — avatar square, name line,
/// email line, chip row — so nothing shifts when the real rows arrive.
class StaffListSkeleton extends StatelessWidget {
  const StaffListSkeleton({super.key, this.rowCount = 5});

  final int rowCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      // The list is a placeholder; scrolling it would be meaningless.
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSizing.screenPadding,
        0,
        AppSizing.screenPadding,
        AppSizing.space24,
      ),
      itemCount: rowCount,
      separatorBuilder: (_, _) => const SizedBox(height: AppSizing.space12),
      itemBuilder: (_, _) => const _StaffRowSkeleton(),
    );
  }
}

class _StaffRowSkeleton extends StatelessWidget {
  const _StaffRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizing.space16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
      ),
      // The shimmer sits inside the card, not around it. Wrapping the card
      // would paint the gradient over its white background too, flattening the
      // whole row into one grey block and losing the layout it exists to show.
      child: const AppShimmer(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppShimmerBox.square(size: AppSizing.avatarMd),
            SizedBox(width: AppSizing.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppShimmerBox(width: 160, height: AppSizing.space16),
                  SizedBox(height: AppSizing.space8),
                  AppShimmerBox(width: 220, height: AppSizing.space12),
                  SizedBox(height: AppSizing.space12),
                  Row(
                    children: [
                      AppShimmerBox(width: 72, height: AppSizing.chipHeight),
                      SizedBox(width: AppSizing.space8),
                      AppShimmerBox(width: 110, height: AppSizing.space12),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: AppSizing.space8),
            Column(
              children: [
                AppShimmerBox.square(size: AppSizing.iconButtonSize),
                SizedBox(height: AppSizing.space8),
                AppShimmerBox.square(size: AppSizing.iconButtonSize),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
