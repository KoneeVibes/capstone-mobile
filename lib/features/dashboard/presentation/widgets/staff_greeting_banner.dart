import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// The blue greeting at the top of the staff home.
class StaffGreetingBanner extends StatelessWidget {
  const StaffGreetingBanner({super.key});

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
                  'Land Search Platform',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textOnPrimary,
                  ),
                ),
                const SizedBox(height: AppSizing.space2),
                // TODO(backend): greet by the signed-in member's name once it is
                // on the session (the JWT carries none; GET /staff/{id} 403s for
                // regular staff).
                Text(
                  'Welcome back',
                  style: AppTextStyles.titleLarge.copyWith(
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
