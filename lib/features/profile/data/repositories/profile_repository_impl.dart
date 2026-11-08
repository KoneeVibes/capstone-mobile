import '../../../../core/utils/error/app_failures.dart';
import '../../../../core/utils/error/error_handler.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/profile_draft.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._remote);

  final ProfileRemoteDataSource _remote;

  @override
  Future<Result<UserProfile>> fetchProfile() => _guard(_remote.fetchProfile);

  @override
  Future<Result<UserProfile>> updateProfile(ProfileDraft draft) =>
      _guard(() => _remote.updateProfile(draft));

  // TODO(backend): call the delete-account endpoint once it exists (ADR 0032).
  @override
  Future<Result<void>> deleteAccount() async =>
      const Err(AppFailures.accountDeletionUnavailable);

  static Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Ok(await action());
    } on Object catch (error, stackTrace) {
      return Err(ErrorHandler.from(error, stackTrace));
    }
  }
}
