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
  const PlaceholderScreen({
    required this.title,
    required this.message,
    super.key,
    this.showAppBar = true,
  });

  final String title;
  final String message;
  final bool showAppBar;

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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
