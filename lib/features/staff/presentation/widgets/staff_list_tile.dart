import 'package:flutter/material.dart';

import '../../../../core/formatting/app_formatters.dart';
import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_chip.dart';
import '../../domain/entities/staff.dart';
import '../../domain/entities/staff_role.dart';

/// One staff member card in the list.
class StaffListTile extends StatelessWidget {
  const StaffListTile({
    required this.staff,
    required this.onEdit,
    required this.onRemove,
    super.key,
  });

  final Staff staff;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final (roleBackground, roleForeground) = _roleColours(staff.role);

    return Container(
      padding: const EdgeInsets.all(AppSizing.space16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppAvatar(
            initials: staff.initials,
            imageUrl: staff.avatarUrl,
            // Deactivated members are dimmed so the list reads at a glance.
            backgroundColor: staff.isActive
                ? AppColors.primary
                : AppColors.disabled,
          ),
          const SizedBox(width: AppSizing.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  staff.fullName,
                  style: AppTextStyles.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSizing.space2),
                Text(
                  staff.email,
                  style: AppTextStyles.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSizing.space8),
                Wrap(
                  spacing: AppSizing.space8,
                  runSpacing: AppSizing.space6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (staff.role.isKnown)
                      AppChip(
                        label: AppFormatters.titleCase(staff.role.apiValue),
                        backgroundColor: roleBackground,
                        foregroundColor: roleForeground,
                      ),
                    // Removal is a soft delete and the list endpoint has no
                    // status filter, so deactivated members keep appearing.
                    // The chip is what tells them apart.
                    if (!staff.isActive)
                      const AppChip(
                        label: 'Inactive',
                        backgroundColor: AppColors.destructiveSoft,
                        foregroundColor: AppColors.destructive,
                      ),
                    if (staff.phone != null)
                      Text(
                        AppFormatters.phone(staff.phone),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSizing.space8),
          Column(
            children: [
              _TileAction(
                icon: Icons.edit_outlined,
                color: AppColors.textPrimary,
                tooltip: 'Edit ${staff.shortName}',
                onPressed: onEdit,
              ),
              const SizedBox(height: AppSizing.space8),
              _TileAction(
                icon: Icons.delete_outline,
                color: AppColors.destructiveIcon,
                tooltip: 'Remove ${staff.shortName}',
                onPressed: onRemove,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// (background, foreground) for the role pill.
  static (Color, Color) _roleColours(StaffRole role) => switch (role) {
    StaffRole.admin => (AppColors.primarySoft, AppColors.primary),
    StaffRole.manager => (AppColors.warningSoft, AppColors.warning),
    StaffRole.regular => (AppColors.successSoft, AppColors.success),
    StaffRole.unknown => (AppColors.surfaceMuted, AppColors.textTertiary),
  };
}

/// Bordered square icon button, as drawn on the list rows.
class _TileAction extends StatelessWidget {
  const _TileAction({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizing.radiusSm),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppSizing.radiusSm),
          child: Ink(
            height: AppSizing.iconButtonSize,
            width: AppSizing.iconButtonSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSizing.radiusSm),
              border: Border.all(
                color: AppColors.border,
                width: AppSizing.borderWidth,
              ),
            ),
            child: Icon(icon, size: AppSizing.iconMd, color: color),
          ),
        ),
      ),
    );
  }
}
