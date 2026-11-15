import 'package:flutter/material.dart';

import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// The message input: the field and send. Text only, as the API is.
///
/// Inert until [enabled] — the conversation must be open.
class ChatComposer extends StatelessWidget {
  const ChatComposer({
    required this.controller,
    required this.enabled,
    required this.canSend,
    required this.hint,
    required this.onSend,
    super.key,
  });

  final TextEditingController controller;
  final bool enabled;

  /// False while a message is on its way. The field stays live, so the
  /// keyboard does not drop between messages.
  final bool canSend;
  final String hint;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
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
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: canSend ? (_) => onSend() : null,
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
          _SendButton(enabled: enabled && canSend, onPressed: onSend),
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
