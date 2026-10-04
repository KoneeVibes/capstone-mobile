import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_providers.dart';

/// Whether onboarding has been seen on this install.
class OnboardingNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => ref.read(authRepositoryProvider).hasSeenOnboarding();

  Future<void> complete() async {
    await ref.read(authRepositoryProvider).markOnboardingSeen();
    state = const AsyncData(true);
  }
}

final onboardingProvider = AsyncNotifierProvider<OnboardingNotifier, bool>(
  OnboardingNotifier.new,
);
