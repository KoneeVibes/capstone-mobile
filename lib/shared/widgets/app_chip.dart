import 'package:flutter/material.dart';

import '../../core/sizing/app_sizing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Small pill used for roles and statuses on list rows.
///
/// Colours are supplied by the caller: mapping a domain value to a colour is a
/// feature concern, not a shared-widget one.
class AppChip extends StatelessWidget {
  const AppChip({
    required this.label,
    super.key,
    this.backgroundColor = AppColors.surfaceMuted,
    this.foregroundColor = AppColors.textSecondary,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizing.space8,
        vertical: AppSizing.space4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSizing.radiusSm),
      ),
      child: Text(
        label,
        style: AppTextStyles.chip.copyWith(color: foregroundColor),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Selectable pill, as used for the role picker in the staff sheets.
class AppChoiceChip extends StatelessWidget {
  const AppChoiceChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
    super.key,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.primary : AppColors.surface,
      borderRadius: BorderRadius.circular(AppSizing.radiusSm),
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(AppSizing.radiusSm),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizing.radiusSm),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: AppSizing.borderWidth,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizing.space12,
              vertical: AppSizing.space8,
            ),
            child: Text(
              label,
              style: AppTextStyles.chip.copyWith(
                color: isSelected
                    ? AppColors.textOnPrimary
                    : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
