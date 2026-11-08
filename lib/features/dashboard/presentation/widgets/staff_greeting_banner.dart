import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/session/signed_in_name.dart';
import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// The blue greeting at the top of the staff home, by first name once the
/// profile has loaded (ADR 0030).
class StaffGreetingBanner extends ConsumerWidget {
  const StaffGreetingBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firstName = ref.watch(signedInFirstNameProvider);

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
                Text(
                  firstName == null
                      ? 'Welcome back'
                      : 'Welcome back, $firstName',
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
