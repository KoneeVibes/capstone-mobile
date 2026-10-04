import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/result.dart';
import '../../domain/entities/auth_session.dart';
import 'auth_providers.dart';

/// The signed-in session, or null. The one source of truth for "who is
/// signed in"; `authOverrides` feeds it to the router and the API client.
///
/// [build] restores the stored session and never throws, so Riverpod has
/// nothing to retry and the splash is never left waiting.
class AuthSessionNotifier extends AsyncNotifier<AuthSession?> {
  /// Set while [signOut] runs: the sign-out request can itself come back 401
  /// (an already-blacklisted token), which must not read as an expiry.
  bool _signingOut = false;

  @override
  Future<AuthSession?> build() =>
      ref.read(authRepositoryProvider).restoreSession();

  Future<Result<AuthSession>> signIn({
    required String email,
    required String password,
  }) async {
    final result = await ref
        .read(authRepositoryProvider)
        .signIn(email: email, password: password);
    if (result case Ok(:final value)) state = AsyncData(value);
    return result;
  }

  Future<void> signOut() async {
    _signingOut = true;
    try {
      await ref.read(authRepositoryProvider).signOut();
    } finally {
      _signingOut = false;
    }
    state = const AsyncData(null);
  }

  /// The server refused the token. Ends the session at once — several requests
  /// can fail together, so only the first does anything.
  Future<void> expire() async {
    if (_signingOut || state.value == null) return;
    state = const AsyncData(null);
    ref.read(sessionExpiredNoticeProvider.notifier).raise();
    await ref.read(authRepositoryProvider).clearSession();
  }
}

final authSessionProvider =
    AsyncNotifierProvider<AuthSessionNotifier, AuthSession?>(
      AuthSessionNotifier.new,
    );

/// Raised when a session ends on a 401, so the login screen can say why the
/// user is there. Consumed once.
class SessionExpiredNoticeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void raise() => state = true;

  /// Whether a notice was pending; clears it either way.
  bool consume() {
    final pending = state;
    state = false;
    return pending;
  }
}

final sessionExpiredNoticeProvider =
    NotifierProvider<SessionExpiredNoticeNotifier, bool>(
      SessionExpiredNoticeNotifier.new,
    );
