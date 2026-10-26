import 'package:flutter/material.dart';

import '../../core/sizing/app_sizing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../extensions/context_extensions.dart';
import 'app_button.dart';

/// Asks the user to confirm an action, resolving to true when they accept.
///
/// Dismissing by tapping outside resolves to false, so a stray tap can never
/// trigger a destructive action. Pass a null [icon] for a text-only dialog, and
/// [stackActions] to put Confirm above Cancel at full width.
Future<bool> showAppConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
  IconData? icon = Icons.delete_outline,
  bool isDestructive = true,
  bool stackActions = false,
}) async {
  context.hideKeyboard();
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
      stackActions: stackActions,
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
    required this.stackActions,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final IconData? icon;
  final bool isDestructive;
  final bool stackActions;

  @override
  Widget build(BuildContext context) {
    final cancel = AppButton(
      label: cancelLabel,
      variant: AppButtonVariant.secondary,
      onPressed: () => Navigator.of(context).pop(false),
    );
    final confirm = AppButton(
      label: confirmLabel,
      variant: isDestructive
          ? AppButtonVariant.destructive
          : AppButtonVariant.primary,
      onPressed: () => Navigator.of(context).pop(true),
    );

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
            if (stackActions) ...[
              confirm,
              const SizedBox(height: AppSizing.space12),
              cancel,
            ] else
              Row(
                children: [
                  Expanded(child: cancel),
                  const SizedBox(width: AppSizing.space12),
                  Expanded(child: confirm),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
