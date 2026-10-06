import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// The blue "Search a Property" header. With [onTap] it opens a new property
/// search and shows an arrow saying so.
class TrackingBanner extends StatelessWidget {
  const TrackingBanner({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSizing.radiusLg);

    return Material(
      color: AppColors.primary,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.all(AppSizing.space20),
          child: _content(),
        ),
      ),
    );
  }

  Widget _content() {
    return Row(
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
        if (onTap != null) ...[
          const SizedBox(width: AppSizing.space12),
          const Icon(
            Icons.arrow_forward_ios,
            size: AppSizing.iconSm,
            color: AppColors.textOnPrimary,
          ),
        ],
      ],
    );
  }
}
