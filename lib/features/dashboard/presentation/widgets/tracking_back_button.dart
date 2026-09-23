import 'package:flutter/material.dart';

import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';

/// The round chevron at the top of the tracking panel.
class TrackingBackButton extends StatelessWidget {
  const TrackingBackButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Back',
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: AppSizing.avatarSm,
          height: AppSizing.avatarSm,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primarySoft,
            border: Border.all(
              color: AppColors.primary,
              width: AppSizing.borderWidth,
            ),
          ),
          child: const Icon(
            Icons.chevron_left,
            size: AppSizing.iconMd,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
