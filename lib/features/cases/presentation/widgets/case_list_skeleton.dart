import 'package:flutter/material.dart';

import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_shimmer.dart';

/// Placeholder rows shown while the cases list loads for the first time.
///
/// Mirrors [CaseListTile]'s geometry — avatar square, name line, status pill,
/// summary, rule, assignment line — so nothing shifts when the real cards
/// arrive.
class CaseListSkeleton extends StatelessWidget {
  const CaseListSkeleton({super.key, this.rowCount = 4});

  final int rowCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      // The list is a placeholder; scrolling it would be meaningless.
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSizing.screenPadding,
        AppSizing.space12,
        AppSizing.screenPadding,
        AppSizing.space24,
      ),
      itemCount: rowCount,
      separatorBuilder: (_, _) => const SizedBox(height: AppSizing.space12),
      itemBuilder: (_, _) => const _CaseRowSkeleton(),
    );
  }
}

class _CaseRowSkeleton extends StatelessWidget {
  const _CaseRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizing.space16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
      ),
      // The shimmer sits inside the card, not around it: wrapping the card
      // would paint the gradient over its white background too and flatten the
      // whole row into one grey block.
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
                  Row(
                    children: [
                      AppShimmerBox(width: 140, height: AppSizing.space16),
                      Spacer(),
                      AppShimmerBox(width: 64, height: AppSizing.chipHeight),
                    ],
                  ),
                  SizedBox(height: AppSizing.space12),
                  AppShimmerBox(height: AppSizing.space12),
                  SizedBox(height: AppSizing.space20),
                  AppShimmerBox(width: 150, height: AppSizing.space12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
