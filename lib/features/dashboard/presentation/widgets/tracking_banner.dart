import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// The blue "Search a Property" header on the dashboard and progress screens.
class TrackingBanner extends StatelessWidget {
  const TrackingBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizing.space20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
      ),
      child: Row(
        children: [
          Image.asset(
            AppAssets.searchPropertyIllustration,
            width: AppSizing.bannerIllustrationSize,
            height: AppSizing.bannerIllustrationSize,
            fit: BoxFit.contain,
            excludeFromSemantics: true,
          ),
          const SizedBox(width: AppSizing.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Search a Property',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textOnPrimary,
                  ),
                ),
                const SizedBox(height: AppSizing.space2),
                Text(
                  'Check any property for litigation before you commit.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textOnPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
