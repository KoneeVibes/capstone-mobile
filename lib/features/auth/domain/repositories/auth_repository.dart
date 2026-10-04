import '../../../../core/utils/result.dart';
import '../entities/auth_session.dart';
import '../entities/sign_up_draft.dart';

/// Sign-in, sign-up, password reset and the stored session.
///
/// Every method returns a [Result] and never throws, except the two that
/// cannot fail from the caller's point of view: [signOut] and [clearSession]
/// always leave the device signed out.
abstract class AuthRepository {
  /// Signs in and stores the token.
  Future<Result<AuthSession>> signIn({
    required String email,
    required String password,
  });

  /// Creates the account and emails a sign-up code. Calling it again for an
  /// unverified account re-sends the code.
  Future<Result<void>> signUp(SignUpDraft draft);

  /// Checks the sign-up code, which activates the account.
  Future<Result<void>> verifySignUp({
    required SignUpDraft draft,
    required String otp,
  });

  /// Emails a password-reset code.
  Future<Result<void>> requestPasswordReset(String email);

  /// Checks the reset code and sets the new password in one call — the API
  /// cannot check the code on its own.
  Future<Result<void>> resetPassword({
    required String email,
    required String otp,
    required String password,
  });

  /// The stored session, or null when there is none or it has expired.
  Future<AuthSession?> restoreSession();

  /// Tells the server, then forgets the token whatever it answered.
  Future<void> signOut();

  /// Forgets the token without telling the server — it already said no.
  Future<void> clearSession();

  Future<bool> hasSeenOnboarding();

  Future<void> markOnboardingSeen();
}
