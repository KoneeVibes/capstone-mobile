import 'package:flutter/material.dart';

import '../../core/sizing/app_sizing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../extensions/context_extensions.dart';

/// Presents [child] in the app's standard bottom sheet.
///
/// Scroll-controlled and keyboard-aware, so a form inside it stays visible when
/// the keyboard opens.
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required String title,
  required Widget child,
  bool isDismissible = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: isDismissible,
    backgroundColor: AppColors.surface,
    barrierColor: AppColors.overlay,
    builder: (context) => AppBottomSheet(
      title: title,
      showClose: isDismissible,
      child: child,
    ),
  );
}

/// Sheet chrome: grabber, title row with a close button, then content.
///
/// Normally reached through [showAppBottomSheet] rather than built directly.
class AppBottomSheet extends StatelessWidget {
  /// Creates the sheet chrome around [child].
  const AppBottomSheet({
    required this.title,
    required this.child,
    super.key,
    this.showClose = true,
  });

  /// The heading, supplied by the calling screen.
  final String title;

  /// The sheet's content, usually a form.
  final Widget child;

  /// Shows the close button. Off for sheets that must not be dismissed.
  final bool showClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Lift the sheet above the keyboard.
      padding: EdgeInsets.only(bottom: context.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: context.screenHeight * AppSizing.sheetMaxHeightFactor,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSizing.space12),
            Container(
              height: AppSizing.sheetGrabberHeight,
              width: AppSizing.sheetGrabberWidth,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppSizing.radiusPill),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizing.space20,
                AppSizing.space20,
                AppSizing.space20,
                AppSizing.space8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(title, style: AppTextStyles.titleLarge),
                  ),
                  if (showClose)
                    _CloseButton(onPressed: () => Navigator.of(context).pop()),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: AppSizing.space20,
                  right: AppSizing.space20,
                  bottom:
                      AppSizing.space24 + context.screenPadding.bottom,
                ),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
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
          child: const Icon(
            Icons.close,
            size: AppSizing.iconMd,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
