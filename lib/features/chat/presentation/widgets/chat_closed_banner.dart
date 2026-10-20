import 'package:flutter/material.dart';

import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// The marker that a conversation has been closed, shown above the composer.
class ChatClosedBanner extends StatelessWidget {
  const ChatClosedBanner({required this.reference, super.key});

  final String reference;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizing.space16,
          vertical: AppSizing.space8,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppSizing.radiusPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              size: AppSizing.iconSm,
              color: AppColors.textOnPrimary,
            ),
            const SizedBox(width: AppSizing.space8),
            Text(
              '$reference Chat Closed',
              style: AppTextStyles.chip.copyWith(
                color: AppColors.textOnPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
