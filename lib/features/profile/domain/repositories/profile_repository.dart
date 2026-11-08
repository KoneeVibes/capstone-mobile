import '../../../../core/utils/result.dart';
import '../entities/profile_draft.dart';
import '../entities/user_profile.dart';

/// The signed-in user's own account.
abstract class ProfileRepository {
  Future<Result<UserProfile>> fetchProfile();

  /// Returns the record as the server saved it.
  Future<Result<UserProfile>> updateProfile(ProfileDraft draft);

  /// Always fails for now: the API has no delete-account endpoint (ADR 0032).
  Future<Result<void>> deleteAccount();
}
