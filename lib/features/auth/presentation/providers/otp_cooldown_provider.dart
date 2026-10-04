import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';

/// Time left before another code can be sent to an email, per email.
///
/// The backend refuses a second code for ten minutes; counting the same ten
/// minutes here keeps the resend link from offering a request that would 409.
/// Counts down to a deadline rather than decrementing, so time spent with the
/// app in the background still counts.
class OtpCooldownNotifier extends Notifier<Duration> {
  OtpCooldownNotifier(this.email);

  final String email;

  Timer? _ticker;
  DateTime? _deadline;

  @override
  Duration build() {
    ref.onDispose(() => _ticker?.cancel());
    return Duration.zero;
  }

  /// Call when a code has just been sent.
  void start() {
    _deadline = clock.now().add(AppConstants.otpResendCooldown);
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _tick();
  }

  void _tick() {
    final remaining = _deadline!.difference(clock.now());
    if (remaining > Duration.zero) {
      state = remaining;
      return;
    }
    _ticker?.cancel();
    state = Duration.zero;
  }
}

final otpCooldownProvider =
    NotifierProvider.family<OtpCooldownNotifier, Duration, String>(
      OtpCooldownNotifier.new,
    );
