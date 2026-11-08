import 'package:flutter/material.dart';

import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/error/app_failure.dart';
import '../../../../shared/widgets/app_button.dart';
import 'tracking_panel.dart';

/// Where a dashboard section would be when it failed to load.
class OverviewFailure extends StatelessWidget {
  const OverviewFailure({
    required this.title,
    required this.failure,
    required this.onRetry,
    super.key,
  });

  /// What failed, e.g. "Couldn't load your cases."
  final String title;

  final AppFailure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return TrackingPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.titleSmall),
          const SizedBox(height: AppSizing.space4),
          Text(failure.message, style: AppTextStyles.bodySmall),
          const SizedBox(height: AppSizing.space12),
          AppButton(
            label: 'Try again',
            variant: AppButtonVariant.secondary,
            expanded: false,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
