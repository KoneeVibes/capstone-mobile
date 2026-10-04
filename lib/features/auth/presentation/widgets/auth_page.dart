import 'package:flutter/material.dart';

import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'auth_back_button.dart';

/// The plain auth layout: back button, title, subtitle, then [children], with
/// an optional [footer] pinned to the bottom while there is room for it.
///
/// Scrolls as one piece, so the keyboard never covers a field.
class AuthPage extends StatelessWidget {
  const AuthPage({
    required this.title,
    required this.children,
    super.key,
    this.subtitle,
    this.footer,
    this.showBack = true,
    this.onBack,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final Widget? footer;
  final bool showBack;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizing.screenPadding),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - AppSizing.screenPadding * 2,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showBack) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: AuthBackButton(onPressed: onBack),
                      ),
                      const SizedBox(height: AppSizing.space24),
                    ],
                    Text(title, style: AppTextStyles.titleLarge),
                    if (subtitle != null) ...[
                      const SizedBox(height: AppSizing.space8),
                      Text(subtitle!, style: AppTextStyles.bodyMedium),
                    ],
                    const SizedBox(height: AppSizing.space24),
                    ...children,
                    if (footer != null) ...[
                      const Spacer(),
                      const SizedBox(height: AppSizing.space24),
                      footer!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
