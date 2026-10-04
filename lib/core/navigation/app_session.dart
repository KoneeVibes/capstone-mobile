import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which side of the product the signed-in user sees.
///
/// One app serves both audiences; the role decides the route branch and the
/// navigation shell.
enum AppRole {
  client,
  staff;

  bool get isStaff => this == AppRole.staff;

  bool get isClient => this == AppRole.client;
}

/// Who is signed in, as far as the router and the features need to know.
class SessionUser extends Equatable {
  const SessionUser({required this.id, required this.role});

  final String id;
  final AppRole role;

  bool get isStaff => role.isStaff;

  bool get isClient => role.isClient;

  @override
  List<Object?> get props => [id, role];
}

// The providers below are the seam between core and the auth feature. Core
// declares them with signed-out defaults; `authOverrides` (features/auth)
// supplies the real values at the composition root, so neither the router nor
// any feature has to import auth.

/// The signed-in user, or null when signed out.
///
/// Providers that hold one user's data watch this, so the next user to sign
/// in starts from nothing.
final sessionProvider = Provider<SessionUser?>((ref) => null);

/// Whether onboarding has been seen on this install.
final hasSeenOnboardingProvider = Provider<bool>((ref) => false);

/// Completes once the stored session has been read. The splash waits on it.
final sessionRestoreProvider = FutureProvider<void>((ref) async {});
