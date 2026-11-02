import 'package:flutter/material.dart';

import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/error/app_failure.dart';
import '../../../../shared/widgets/app_button.dart';
import 'tracking_panel.dart';

/// Where the overview cards would be when the counts failed to load.
class OverviewFailure extends StatelessWidget {
  const OverviewFailure({
    required this.failure,
    required this.onRetry,
    super.key,
  });

  final AppFailure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return TrackingPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Couldn't load your cases.",
            style: AppTextStyles.titleSmall,
          ),
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
