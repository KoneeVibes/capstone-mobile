import 'package:flutter_riverpod/misc.dart';

import '../../../../core/navigation/app_session.dart';
import '../../../../core/network/api_provider.dart';
import 'auth_session_provider.dart';
import 'onboarding_provider.dart';

/// Plugs auth into the seams core declares, at the composition root
/// (`main.dart`). Core and the other features read these providers and never
/// import auth.
///
/// The token supplier and the 401 handler read the session lazily, inside
/// their callbacks: watching it would rebuild Dio — and every datasource — on
/// each sign-in, and would make the session depend on the client it uses.
final List<Override> authOverrides = [
  sessionProvider.overrideWith(
    (ref) => ref.watch(authSessionProvider).value?.user,
  ),
  hasSeenOnboardingProvider.overrideWith(
    (ref) => ref.watch(onboardingProvider).value ?? false,
  ),
  sessionRestoreProvider.overrideWith((ref) async {
    await Future.wait([
      ref.watch(authSessionProvider.future),
      ref.watch(onboardingProvider.future),
    ]);
  }),
  authTokenProvider.overrideWith(
    (ref) =>
        () async => ref.read(authSessionProvider).value?.token,
  ),
  unauthorizedHandlerProvider.overrideWith(
    (ref) =>
        () => ref.read(authSessionProvider.notifier).expire(),
  ),
];
