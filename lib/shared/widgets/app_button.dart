import 'package:flutter/material.dart';

import '../../core/sizing/app_sizing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

enum AppButtonVariant {
  /// Filled call to action.
  primary,

  /// Outlined, for the secondary choice beside a primary action.
  secondary,

  /// Filled red, for irreversible actions.
  destructive,
}

/// The app's button.
///
/// Passing null to [onPressed] disables it. While [isLoading] the button stays
/// laid out at the same size and swallows taps, so a form cannot be submitted
/// twice.
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;

  /// Stretch to the available width. Turn off inside a Row.
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;
    final (background, foreground, border) = _palette(isEnabled);

    final button = SizedBox(
      height: AppSizing.buttonHeight,
      width: expanded ? double.infinity : null,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: BorderRadius.circular(AppSizing.radiusMd),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSizing.radiusMd),
              border: border == null
                  ? null
                  : Border.all(color: border, width: AppSizing.borderWidth),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizing.space20,
              ),
              child: Center(child: _content(foreground)),
            ),
          ),
        ),
      ),
    );

    return expanded ? button : IntrinsicWidth(child: button);
  }

  Widget _content(Color foreground) {
    if (isLoading) {
      return SizedBox(
        height: AppSizing.iconMd,
        width: AppSizing.iconMd,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(foreground),
        ),
      );
    }

    final text = Text(
      label,
      style: AppTextStyles.button.copyWith(color: foreground),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    if (icon == null) return text;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppSizing.iconMd, color: foreground),
        const SizedBox(width: AppSizing.space8),
        Flexible(child: text),
      ],
    );
  }

  /// (background, foreground, border)
  (Color, Color, Color?) _palette(bool isEnabled) {
    if (!isEnabled) {
      return switch (variant) {
        AppButtonVariant.secondary => (
          AppColors.surface,
          AppColors.disabledText,
          AppColors.border,
        ),
        _ => (AppColors.disabled, AppColors.surface, null),
      };
    }

    return switch (variant) {
      AppButtonVariant.primary => (
        AppColors.primaryBright,
        AppColors.textOnPrimary,
        null,
      ),
      AppButtonVariant.secondary => (
        AppColors.surface,
        AppColors.textPrimary,
        AppColors.border,
      ),
      AppButtonVariant.destructive => (
        AppColors.destructive,
        AppColors.textOnPrimary,
        null,
      ),
    };
  }
}
