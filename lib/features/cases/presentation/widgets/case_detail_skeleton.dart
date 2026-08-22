import 'package:flutter/material.dart';

import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_shimmer.dart';

/// Placeholder card shown while a case loads.
///
/// Mirrors the detail card's geometry — heading, rule, section title, then
/// label-and-value pairs — so the real content lands in place.
class CaseDetailSkeleton extends StatelessWidget {
  const CaseDetailSkeleton({super.key, this.rowCount = 7});

  final int rowCount;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSizing.screenPadding),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        ),
        // The shimmer sits inside the card so the gradient does not paint over
        // the card's own white background.
        child: AppShimmer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(AppSizing.space20),
                child: AppShimmerBox(width: 120, height: AppSizing.space16),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(AppSizing.space20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppShimmerBox(width: 90, height: AppSizing.space16),
                    const SizedBox(height: AppSizing.space20),
                    for (var i = 0; i < rowCount; i++) ...[
                      const AppShimmerBox(width: 100),
                      const SizedBox(height: AppSizing.space8),
                      const AppShimmerBox(width: 190, height: AppSizing.space16),
                      if (i != rowCount - 1)
                        const SizedBox(height: AppSizing.space20),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
