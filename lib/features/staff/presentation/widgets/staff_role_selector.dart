import 'package:flutter/material.dart';

import '../../../../core/formatting/app_formatters.dart';
import '../../../../core/session/staff_role.dart';
import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_chip.dart';

/// Horizontally scrolling role picker.
///
/// Labels come from [StaffRole.apiValue] through [AppFormatters.titleCase], so
/// the display name cannot drift out of step with what the API expects.
class StaffRoleSelector extends StatelessWidget {
  const StaffRoleSelector({
    required this.label,
    required this.selected,
    required this.onSelected,
    super.key,
    this.errorText,
  });

  final String label;
  final StaffRole selected;
  final ValueChanged<StaffRole> onSelected;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    // A role that is held but never offered (super-admin) still shows, so the
    // form does not look as if the member has none.
    final roles = [
      if (selected.isKnown && !selected.isAssignable) selected,
      ...StaffRole.assignable,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: AppSizing.space8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final role in roles) ...[
                AppChoiceChip(
                  label: AppFormatters.titleCase(role.apiValue),
                  isSelected: role == selected,
                  onSelected: () => onSelected(role),
                ),
                if (role != roles.last)
                  const SizedBox(width: AppSizing.space8),
              ],
            ],
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: AppSizing.space6),
          Text(
            errorText!,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.destructive,
            ),
          ),
        ],
      ],
    );
  }
}
