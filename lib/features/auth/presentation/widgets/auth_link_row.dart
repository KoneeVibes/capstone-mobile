import 'package:flutter/material.dart';

import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// "Not a member? Register now" — a line of copy ending in a tappable link.
class AuthLinkRow extends StatelessWidget {
  const AuthLinkRow({
    required this.prompt,
    required this.action,
    required this.onPressed,
    super.key,
  });

  final String prompt;
  final String action;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(prompt, style: AppTextStyles.bodyMedium),
        const SizedBox(width: AppSizing.space4),
        AuthLink(label: action, onPressed: onPressed),
      ],
    );
  }
}

/// A bare text link with a comfortable tap target.
class AuthLink extends StatelessWidget {
  const AuthLink({required this.label, required this.onPressed, super.key});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppSizing.radiusSm),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSizing.space8),
          child: Text(
            label,
            style: onPressed == null
                ? AppTextStyles.link.copyWith(
                    color: AppTextStyles.bodyMedium.color,
                  )
                : AppTextStyles.link,
          ),
        ),
      ),
    );
  }
}
