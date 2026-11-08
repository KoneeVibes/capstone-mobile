import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Both homes' header: brand mark, name, and the notifications bell the
/// router passes in.
class HomeTopBar extends StatelessWidget {
  const HomeTopBar({required this.bell, super.key});

  final Widget bell;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizing.screenPadding,
          vertical: AppSizing.space4,
        ),
        child: Row(
          children: [
            // Same width as the bell, so the name sits in the true centre.
            SizedBox(
              width: AppSizing.space48,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Image.asset(
                  AppAssets.appIcon,
                  width: AppSizing.topBarLogo,
                  height: AppSizing.topBarLogo,
                  excludeFromSemantics: true,
                ),
              ),
            ),
            const Expanded(
              child: Text(
                'PropertyIntel',
                style: AppTextStyles.titleMedium,
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(
              width: AppSizing.space48,
              child: Align(alignment: Alignment.centerRight, child: bell),
            ),
          ],
        ),
      ),
    );
  }
}
