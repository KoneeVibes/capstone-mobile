import 'package:flutter/material.dart';

import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// A labelled picker in the same frame as `AppTextField`. Disabled while
/// [options] is empty — an LGA cannot be chosen before its state.
class SearchDropdownField extends StatelessWidget {
  const SearchDropdownField({
    required this.label,
    required this.hint,
    required this.value,
    required this.options,
    required this.onChanged,
    super.key,
    this.errorText,
  });

  final String label;
  final String hint;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: AppSizing.space8),
        DropdownButtonFormField<String>(
          // Keyed on the value so a parent clearing it (a new state empties
          // the LGA) resets the field; initialValue alone is read once.
          key: ValueKey(value),
          initialValue: value,
          isExpanded: true,
          onChanged: options.isEmpty ? null : onChanged,
          style: AppTextStyles.bodyLarge,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.textSecondary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            prefixIcon: const Icon(
              Icons.location_on_outlined,
              size: AppSizing.iconMd,
              color: AppColors.textSecondary,
            ),
          ),
          items: [
            for (final option in options)
              DropdownMenuItem(
                value: option,
                child: Text(option, overflow: TextOverflow.ellipsis),
              ),
          ],
        ),
      ],
    );
  }
}
