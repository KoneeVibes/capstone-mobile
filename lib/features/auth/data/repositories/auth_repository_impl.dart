import '../../../../core/utils/error/app_failure.dart';
import '../../../../core/utils/error/app_failures.dart';
import '../../../../core/utils/error/error_handler.dart';
import '../../../../core/utils/error/failure_type.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/sign_up_draft.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_session_model.dart';

/// Converts the datasources' exceptions into [Result] values.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(
    this._remote,
    this._local, {
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now;

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;
  final DateTime Function() _now;

  @override
  Future<Result<AuthSession>> signIn({
    required String email,
    required String password,
  }) => _guard(() async {
    final token = await _remote.signIn(email: email, password: password);
    // Decoded before it is stored, so a token this build cannot route never
    // outlives the attempt.
    final session = AuthSessionModel.fromToken(token);
    await _local.saveToken(token);
    return session;
  });

  @override
  Future<Result<void>> signUp(SignUpDraft draft) =>
      _guard(() => _remote.signUp(draft));

  @override
  Future<Result<void>> verifySignUp({
    required SignUpDraft draft,
    required String otp,
  }) => _guardOtp(() => _remote.verifySignUp(draft: draft, otp: otp));

  @override
  Future<Result<void>> requestPasswordReset(String email) =>
      _guard(() => _remote.requestPasswordReset(email));

  @override
  Future<Result<void>> resetPassword({
    required String email,
    required String otp,
    required String password,
  }) => _guardOtp(
    () => _remote.resetPassword(email: email, otp: otp, password: password),
  );

  @override
  Future<AuthSession?> restoreSession() async {
    try {
      // The Keychain survives an uninstall but preferences do not, so a fresh
      // install that has not seen onboarding must not resume an old session.
      if (!await _local.hasSeenOnboarding()) {
        await _local.deleteToken();
        return null;
      }

      final token = await _local.readToken();
      if (token == null || token.isEmpty) return null;

      final session = AuthSessionModel.fromToken(token);
      if (session.isExpiredAt(_now())) {
        await _local.deleteToken();
        return null;
      }
      return session;
    } on Object {
      // Unreadable storage or a token this build cannot decode: start signed
      // out rather than stuck on the splash.
      await clearSession();
      return null;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _remote.signOut();
    } on Object {
      // Best effort: the server keeps its blacklist in memory, and the device
      // forgets the token either way.
    }
    await clearSession();
  }

  @override
  Future<void> clearSession() async {
    try {
      await _local.deleteToken();
    } on Object {
      // Nothing left to do; the session is gone from memory regardless.
    }
  }

  @override
  Future<bool> hasSeenOnboarding() async {
    try {
      return await _local.hasSeenOnboarding();
    } on Object {
      return false;
    }
  }

  @override
  Future<void> markOnboardingSeen() async {
    try {
      await _local.markOnboardingSeen();
    } on Object {
      // Worst case onboarding shows once more on the next launch.
    }
  }

  /// A code the server would not take, whichever way it said so: 400 "OTP not
  /// valid" for a wrong code, 409 "OTP not found" for an expired or used one
  /// (verified live 4 Oct 2026). 400 also covers malformed requests, so only
  /// a 400 that names the OTP counts.
  static Future<Result<void>> _guardOtp(Future<void> Function() action) async {
    final result = await _guard(action);
    return switch (result) {
      Err(:final failure) when _isRejectedCode(failure) =>
        const Err(AppFailures.invalidOtp),
      _ => result,
    };
  }

  static bool _isRejectedCode(AppFailure failure) =>
      failure.type == FailureType.conflict ||
      (failure.statusCode == 400 &&
          failure.message.toLowerCase().contains('otp'));

  static Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Ok(await action());
    } on Object catch (error, stackTrace) {
      return Err(ErrorHandler.from(error, stackTrace));
    }
  }
}
