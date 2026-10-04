import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/sizing/app_sizing.dart';
import '../../core/theme/app_text_styles.dart';

/// Stand-in for a screen that has not been built yet.
///
/// Every route the app declares needs somewhere to land; this keeps navigation
/// exercisable while features arrive one at a time. Replace usages as the real
/// screens land — nothing should still point here at release.
class PlaceholderScreen extends StatelessWidget {
  /// Creates a placeholder. The route that mounts it supplies the copy.
  const PlaceholderScreen({
    required this.title,
    required this.message,
    super.key,
    this.showAppBar = true,
    this.action,
  });

  /// Names the screen-to-be, in the app bar and above [message].
  final String title;

  /// One line on what will live here.
  final String message;

  /// Off for a full-bleed placeholder with no app bar.
  final bool showAppBar;

  /// Optional control rendered below the message, so a placeholder can still
  /// lead somewhere while the real screen is being built.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar ? AppBar(title: Text(title)) : null,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizing.space32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  AppAssets.logo,
                  height: AppSizing.space48,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: AppSizing.space24),
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
                if (action != null) ...[
                  const SizedBox(height: AppSizing.space24),
                  action!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
