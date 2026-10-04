import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/error/app_failures.dart';
import '../../../../core/utils/error/error_handler.dart';
import '../../../../core/utils/result.dart';
import 'auth_providers.dart';
import 'otp_cooldown_provider.dart';

/// Where a password reset has got to.
class PasswordResetFlow extends Equatable {
  const PasswordResetFlow({
    required this.email,
    this.otp = '',
    this.codeRejected = false,
  });

  final String email;
  final String otp;

  /// The last reset failed on the code. The code screen shows "Wrong code"
  /// when the user is sent back to it.
  final bool codeRejected;

  PasswordResetFlow copyWith({String? otp, bool? codeRejected}) =>
      PasswordResetFlow(
        email: email,
        otp: otp ?? this.otp,
        codeRejected: codeRejected ?? this.codeRejected,
      );

  @override
  List<Object?> get props => [email, otp, codeRejected];
}

/// Email → code → new password. The API checks the code only together with
/// the new password, so the code screen just collects it and a wrong code
/// surfaces on [reset].
class PasswordResetFlowNotifier extends Notifier<PasswordResetFlow?> {
  @override
  PasswordResetFlow? build() => null;

  Future<Result<void>> requestCode(String email) async {
    final result = await ref
        .read(authRepositoryProvider)
        .requestPasswordReset(email);
    if (result.isOk) {
      state = PasswordResetFlow(email: email);
      ref.read(otpCooldownProvider(email).notifier).start();
    }
    return result;
  }

  Future<Result<void>> resend() => _withFlow((flow) => requestCode(flow.email));

  void enterCode(String otp) =>
      state = state?.copyWith(otp: otp, codeRejected: false);

  Future<Result<void>> reset(String password) => _withFlow((flow) async {
    final result = await ref
        .read(authRepositoryProvider)
        .resetPassword(email: flow.email, otp: flow.otp, password: password);
    if (result.failureOrNull == AppFailures.invalidOtp) {
      state = flow.copyWith(otp: '', codeRejected: true);
    }
    return result;
  });

  void clear() => state = null;

  Future<Result<void>> _withFlow(
    Future<Result<void>> Function(PasswordResetFlow flow) action,
  ) async {
    final flow = state;
    if (flow == null) {
      return Err(ErrorHandler.from(StateError('No reset in progress.')));
    }
    return action(flow);
  }
}

final passwordResetFlowProvider =
    NotifierProvider<PasswordResetFlowNotifier, PasswordResetFlow?>(
      PasswordResetFlowNotifier.new,
    );
