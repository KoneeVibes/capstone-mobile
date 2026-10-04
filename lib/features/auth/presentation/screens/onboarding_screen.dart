import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/auth_hero.dart';

/// Shown once per install. One page for now — the designs draw three dots but
/// only one page exists, so the dots are left out until the others do.
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  Future<void> _finish(BuildContext context, WidgetRef ref) async {
    await ref.read(onboardingProvider.notifier).complete();
    if (context.mounted) context.goNamed(AppRoutes.loginName);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthHero(
                asset: AppAssets.onboardingIllustration,
                height: constraints.maxHeight * AppSizing.onboardingHeroFraction,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizing.space24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Know a property is legit before you pay.',
                        style: AppTextStyles.titleLarge,
                      ),
                      const SizedBox(height: AppSizing.space12),
                      const Text(
                        'We check any property against known litigation and '
                        'disputes on record, then send you a report you can '
                        'trust.',
                        style: AppTextStyles.bodyMedium,
                      ),
                      const Spacer(),
                      AppButton(
                        label: 'Next',
                        onPressed: () => _finish(context, ref),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
