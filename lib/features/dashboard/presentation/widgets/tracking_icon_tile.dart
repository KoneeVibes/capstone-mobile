import 'package:flutter/material.dart';

import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';

/// The soft blue clock tile beside a tracked case.
class TrackingIconTile extends StatelessWidget {
  const TrackingIconTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizing.iconButtonSize,
      height: AppSizing.iconButtonSize,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
      ),
      child: const Icon(
        Icons.schedule,
        size: AppSizing.iconMd,
        color: AppColors.primaryBright,
      ),
    );
  }
}
