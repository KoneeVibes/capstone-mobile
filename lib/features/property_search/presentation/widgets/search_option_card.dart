import 'package:flutter/material.dart';

import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// A selectable card: a title, an optional line under it, and a tick when
/// chosen. Single or multiple choice is the caller's business.
class SearchOptionCard extends StatelessWidget {
  const SearchOptionCard({
    required this.title,
    required this.isSelected,
    required this.onTap,
    super.key,
    this.hint,
  });

  final String title;
  final String? hint;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSizing.radiusMd);

    return Semantics(
      selected: isSelected,
      button: true,
      child: Material(
        color: isSelected ? AppColors.primarySoft : AppColors.surface,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Ink(
            padding: const EdgeInsets.all(AppSizing.space12),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected
                    ? AppSizing.borderWidthFocused
                    : AppSizing.borderWidth,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.titleSmall),
                      if (hint != null) ...[
                        const SizedBox(height: AppSizing.space2),
                        Text(hint!, style: AppTextStyles.bodySmall),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSizing.space8),
                Icon(
                  isSelected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  size: AppSizing.iconMd,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
