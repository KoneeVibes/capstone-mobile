import 'package:flutter/material.dart';

import '../../core/sizing/app_sizing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// One row of a settings-style list: icon, label and a chevron.
///
/// [destructive] draws it in red, for actions such as deleting an account.
/// While [busy], a small spinner replaces the chevron and taps are ignored.
class AppMenuTile extends StatelessWidget {
  /// Creates a row; the caller supplies its copy.
  const AppMenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
    this.destructive = false,
    this.busy = false,
  });

  /// Leading glyph.
  final IconData icon;

  /// What the row does, e.g. "Update Profile".
  final String label;

  /// Null disables the row.
  final VoidCallback? onTap;

  /// Red, for an action that cannot be undone.
  final bool destructive;

  /// Work in progress: a spinner instead of the chevron.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.destructive : AppColors.textPrimary;

    return InkWell(
      onTap: busy ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizing.space16,
          vertical: AppSizing.space16,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: AppSizing.iconMd,
              color: destructive
                  ? AppColors.destructiveIcon
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSizing.space16),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(color: color),
              ),
            ),
            if (busy)
              const SizedBox(
                width: AppSizing.iconSm,
                height: AppSizing.iconSm,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                Icons.chevron_right,
                size: AppSizing.iconMd,
                color: destructive
                    ? AppColors.destructiveIcon
                    : AppColors.textSecondary,
              ),
          ],
        ),
      ),
    );
  }
}
