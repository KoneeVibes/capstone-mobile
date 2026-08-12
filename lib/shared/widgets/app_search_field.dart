import 'package:flutter/material.dart';

import '../../core/sizing/app_sizing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Pill-shaped search input with a leading magnifier.
///
/// Set [enabled] to false to show the field without accepting input — used
/// where the UI is in place but the backing query is not yet available.
class AppSearchField extends StatelessWidget {
  const AppSearchField({
    required this.hint,
    super.key,
    this.controller,
    this.onChanged,
    this.onClear,
    this.enabled = true,
    this.autofocus = false,
  });

  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final bool enabled;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final hasText = controller?.text.isNotEmpty ?? false;

    return SizedBox(
      height: AppSizing.searchFieldHeight,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        enabled: enabled,
        autofocus: autofocus,
        textInputAction: TextInputAction.search,
        style: AppTextStyles.bodyLarge,
        decoration: InputDecoration(
          hintText: hint,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            vertical: AppSizing.space12,
          ),
          prefixIcon: const Icon(
            Icons.search,
            size: AppSizing.iconMd,
            color: AppColors.textTertiary,
          ),
          suffixIcon: hasText && onClear != null
              ? IconButton(
                  icon: const Icon(Icons.close, size: AppSizing.iconSm),
                  color: AppColors.textTertiary,
                  onPressed: onClear,
                )
              : null,
          border: _border(AppColors.border),
          enabledBorder: _border(AppColors.border),
          disabledBorder: _border(AppColors.border),
          focusedBorder: _border(
            AppColors.primary,
            width: AppSizing.borderWidthFocused,
          ),
        ),
      ),
    );
  }

  OutlineInputBorder _border(
    Color color, {
    double width = AppSizing.borderWidth,
  }) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppSizing.radiusPill),
    borderSide: BorderSide(color: color, width: width),
  );
}
