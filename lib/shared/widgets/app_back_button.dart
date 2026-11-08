import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/sizing/app_sizing.dart';
import '../../core/theme/app_colors.dart';

/// The outlined square chevron the designs put top-left. Pops by default.
class AppBackButton extends StatelessWidget {
  /// Creates the button; it pops unless [onPressed] says otherwise.
  const AppBackButton({super.key, this.onPressed});

  /// Replaces the default pop.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Back',
      child: InkWell(
        onTap: onPressed ?? () => context.pop(),
        borderRadius: BorderRadius.circular(AppSizing.radiusSm),
        child: Container(
          width: AppSizing.avatarSm,
          height: AppSizing.avatarSm,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizing.radiusSm),
            border: Border.all(
              color: AppColors.border,
              width: AppSizing.borderWidth,
            ),
          ),
          child: const Icon(
            Icons.chevron_left,
            size: AppSizing.iconMd,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
