import 'package:flutter/material.dart';

import '../../core/sizing/app_sizing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Small pill used for roles and statuses on list rows.
///
/// Colours are supplied by the caller: mapping a domain value to a colour is a
/// feature concern, not a shared-widget one.
class AppChip extends StatelessWidget {
  /// Creates a pill, grey unless the caller passes a status colour pair.
  const AppChip({
    required this.label,
    super.key,
    this.backgroundColor = AppColors.surfaceMuted,
    this.foregroundColor = AppColors.textSecondary,
  });

  /// The text, truncated to one line.
  final String label;

  /// Fill colour — usually one of the `*Soft` colours.
  final Color backgroundColor;

  /// Text colour — usually the matching strong colour.
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

/// How much weight a selected [AppChoiceChip] carries.
enum AppChoiceChipStyle {
  /// Brand blue when selected, outlined when not. For a chip that sets a value
  /// on a record, such as the role picker in the staff sheets.
  brand,

  /// Greyscale, filled either way. For a chip that narrows what a list shows
  /// rather than changing anything, such as the cases filter tabs — the brand
  /// blue would read as an edit.
  neutral,
}

/// Selectable pill.
class AppChoiceChip extends StatelessWidget {
  /// Creates a chip. The caller owns selection; this only reports taps.
  const AppChoiceChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
    super.key,
    this.style = AppChoiceChipStyle.brand,
    this.enabled = true,
  });

  /// The chip's text.
  final String label;

  /// Draws the chip in its selected state.
  final bool isSelected;

  /// Called on tap, whether or not the chip is already selected.
  final VoidCallback onSelected;

  /// Brand or neutral; see [AppChoiceChipStyle].
  final AppChoiceChipStyle style;

  /// Set false to show the chip without accepting taps, so a filter bar stays
  /// in place — and stops shifting the layout — while its list loads.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, border) = _palette();

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(AppSizing.radiusSm),
      child: InkWell(
        onTap: enabled ? onSelected : null,
        borderRadius: BorderRadius.circular(AppSizing.radiusSm),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizing.radiusSm),
            border: border == null
                ? null
                : Border.all(color: border, width: AppSizing.borderWidth),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizing.space12,
              vertical: AppSizing.space8,
            ),
            child: Text(
              label,
              style: AppTextStyles.chip.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// (background, foreground, border)
  (Color, Color, Color?) _palette() => switch (style) {
    AppChoiceChipStyle.brand when isSelected => (
      AppColors.primary,
      AppColors.textOnPrimary,
      AppColors.primary,
    ),
    AppChoiceChipStyle.brand => (
      AppColors.surface,
      AppColors.textPrimary,
      AppColors.border,
    ),
    AppChoiceChipStyle.neutral when isSelected => (
      AppColors.surfaceSelected,
      AppColors.textPrimary,
      null,
    ),
    AppChoiceChipStyle.neutral => (
      AppColors.surfaceMuted,
      AppColors.textSecondary,
      null,
    ),
  };
}
