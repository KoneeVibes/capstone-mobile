import 'package:flutter/material.dart';

import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/error/app_failure.dart';

/// Inline failure banner for the case sheets and the home queue — in a sheet a
/// snackbar would sit behind it. Renders [AppFailure.message] and nothing else.
class CaseErrorBanner extends StatelessWidget {
  const CaseErrorBanner({required this.failure, super.key, this.onRetry});

  final AppFailure failure;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final showRetry = onRetry != null && failure.isRetryable;

    return Container(
      padding: const EdgeInsets.all(AppSizing.space12),
      decoration: BoxDecoration(
        color: AppColors.destructiveSoft,
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            size: AppSizing.iconSm,
            color: AppColors.destructive,
          ),
          const SizedBox(width: AppSizing.space8),
          Expanded(
            child: Text(
              failure.message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.destructive,
              ),
            ),
          ),
          if (showRetry)
            TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}
