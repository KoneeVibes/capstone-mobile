import 'package:flutter/material.dart';

import '../../core/sizing/app_sizing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'app_button.dart';

/// Asks the user to confirm an action, resolving to true when they accept.
///
/// Dismissing by tapping outside resolves to false, so a stray tap can never
/// trigger a destructive action. Pass a null [icon] for a text-only dialog.
Future<bool> showAppConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
  IconData? icon = Icons.delete_outline,
  bool isDestructive = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierColor: AppColors.overlay,
    builder: (context) => _AppConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      icon: icon,
      isDestructive: isDestructive,
    ),
  );
  return result ?? false;
}

class _AppConfirmDialog extends StatelessWidget {
  const _AppConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.icon,
    required this.isDestructive,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final IconData? icon;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSizing.space24),
      child: Padding(
        padding: const EdgeInsets.all(AppSizing.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Container(
                height: AppSizing.stateIconBox,
                width: AppSizing.stateIconBox,
                decoration: BoxDecoration(
                  color: isDestructive
                      ? AppColors.destructiveSoft
                      : AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppSizing.radiusLg),
                ),
                child: Icon(
                  icon,
                  size: AppSizing.iconXl,
                  color: isDestructive
                      ? AppColors.destructiveIcon
                      : AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSizing.space20),
            ],
            Text(
              title,
              style: AppTextStyles.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizing.space8),
            Text(
              message,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizing.space24),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: cancelLabel,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: AppSizing.space12),
                Expanded(
                  child: AppButton(
                    label: confirmLabel,
                    variant: isDestructive
                        ? AppButtonVariant.destructive
                        : AppButtonVariant.primary,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
