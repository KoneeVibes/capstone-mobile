import 'dart:async';

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
  Future<AuthSession?> build() async {
    final session = await ref.read(authRepositoryProvider).restoreSession();
    // The stored role opens the app at once; this picks up a change made on
    // the server since, without holding the splash.
    if (session != null && session.isStaff) {
      unawaited(Future(() => _refreshStaffRole(session)));
    }
    return session;
  }

  /// A failure keeps the stored role; a 401 ends the session through the
  /// API client like any other request.
  Future<void> _refreshStaffRole(AuthSession session) async {
    final result = await ref
        .read(authRepositoryProvider)
        .refreshStaffRole(session);
    if (!ref.mounted) return;
    // Dropped if the user signed out, or in as someone else, meanwhile.
    if (result case Ok(:final value) when state.value?.token == session.token) {
      state = AsyncData(value);
    }
  }

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
    ref
        .read(sessionEndNoticeProvider.notifier)
        .raise(SessionEndNotice.signedOut);
    state = const AsyncData(null);
  }

  /// The server refused the token. Ends the session at once — several requests
  /// can fail together, so only the first does anything.
  Future<void> expire() async {
    if (_signingOut || state.value == null) return;
    state = const AsyncData(null);
    ref.read(sessionEndNoticeProvider.notifier).raise(SessionEndNotice.expired);
    await ref.read(authRepositoryProvider).clearSession();
  }
}

final authSessionProvider =
    AsyncNotifierProvider<AuthSessionNotifier, AuthSession?>(
      AuthSessionNotifier.new,
    );

/// Why the last session ended: a 401, or the user logging out.
enum SessionEndNotice { expired, signedOut }

/// Raised when a session ends, so the login screen can say why the user is
/// there. Consumed once.
class SessionEndNoticeNotifier extends Notifier<SessionEndNotice?> {
  @override
  SessionEndNotice? build() => null;

  void raise(SessionEndNotice notice) => state = notice;

  /// The pending notice, if any; clears it either way.
  SessionEndNotice? consume() {
    final pending = state;
    state = null;
    return pending;
  }
}

final sessionEndNoticeProvider =
    NotifierProvider<SessionEndNoticeNotifier, SessionEndNotice?>(
      SessionEndNoticeNotifier.new,
    );
