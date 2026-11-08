import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../../../../shared/widgets/app_button.dart';

/// The end of a reset. Every way out leads to [exitRouteName]: login when
/// signed out, the Profile tab when the reset started there.
class PasswordChangedScreen extends StatelessWidget {
  const PasswordChangedScreen({
    super.key,
    this.exitRouteName = AppRoutes.loginName,
    this.exitLabel = 'Back to login',
  });

  final String exitRouteName;
  final String exitLabel;

  @override
  Widget build(BuildContext context) {
    void exit() => context.goNamed(exitRouteName);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: AppBackButton(onPressed: exit),
              ),
              const SizedBox(height: AppSizing.space48),
              const Text(
                'Password changed',
                style: AppTextStyles.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizing.space8),
              const Text(
                'Your password has been changed successfully.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizing.space24),
              AppButton(label: exitLabel, onPressed: exit),
            ],
          ),
        ),
      ),
    );
  }
}
