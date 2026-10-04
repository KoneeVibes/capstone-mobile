import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/error/error_handler.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/sign_up_draft.dart';
import 'auth_providers.dart';
import 'otp_cooldown_provider.dart';

/// The sign-up in progress: the draft is kept from the register form until
/// the emailed code is verified, because verifying sends the details again
/// and the app then signs in with the password.
///
/// Memory only — a restart mid-flow starts again from the register form.
class SignUpFlowNotifier extends Notifier<SignUpDraft?> {
  @override
  SignUpDraft? build() => null;

  /// Creates the account and emails the code.
  Future<Result<void>> submit(SignUpDraft draft) async {
    final result = await ref.read(authRepositoryProvider).signUp(draft);
    if (result.isOk) {
      state = draft;
      ref.read(otpCooldownProvider(draft.email).notifier).start();
    }
    return result;
  }

  /// Sign-up again re-sends the code for an account not yet verified.
  Future<Result<void>> resend() => _withDraft((draft) => submit(draft));

  Future<Result<void>> verify(String otp) => _withDraft(
    (draft) =>
        ref.read(authRepositoryProvider).verifySignUp(draft: draft, otp: otp),
  );

  void clear() => state = null;

  Future<Result<void>> _withDraft(
    Future<Result<void>> Function(SignUpDraft draft) action,
  ) async {
    final draft = state;
    if (draft == null) {
      return Err(ErrorHandler.from(StateError('No sign-up in progress.')));
    }
    return action(draft);
  }
}

final signUpFlowProvider = NotifierProvider<SignUpFlowNotifier, SignUpDraft?>(
  SignUpFlowNotifier.new,
);
