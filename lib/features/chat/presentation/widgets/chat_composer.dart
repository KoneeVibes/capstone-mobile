import 'package:flutter/material.dart';

import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// The message input: an attach affordance, the field, and send.
///
/// Inert until [enabled] — the conversation must be opened first.
class ChatComposer extends StatelessWidget {
  const ChatComposer({
    required this.controller,
    required this.enabled,
    required this.hint,
    required this.onSend,
    super.key,
  });

  final TextEditingController controller;
  final bool enabled;
  final String hint;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final iconColor = enabled
        ? AppColors.textSecondary
        : AppColors.disabledText;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizing.space12,
        vertical: AppSizing.space8,
      ),
      decoration: BoxDecoration(
        color: enabled ? AppColors.surface : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
        border: Border.all(
          color: AppColors.border,
          width: AppSizing.borderWidth,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Attaching is part of the design; not wired in the mock.
          Icon(Icons.attach_file, size: AppSizing.iconMd, color: iconColor),
          const SizedBox(width: AppSizing.space8),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              style: AppTextStyles.bodyLarge,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: AppTextStyles.hint,
              ),
            ),
          ),
          const SizedBox(width: AppSizing.space8),
          _SendButton(enabled: enabled, onPressed: onSend),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSizing.radiusPill);

    return Material(
      color: enabled ? AppColors.primaryBright : AppColors.disabled,
      borderRadius: radius,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: radius,
        child: const SizedBox(
          width: AppSizing.iconButtonSize,
          height: AppSizing.iconButtonSize,
          child: Icon(
            Icons.arrow_upward,
            size: AppSizing.iconMd,
            color: AppColors.textOnPrimary,
          ),
        ),
      ),
    );
  }
}
