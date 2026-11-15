import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/profile_draft.dart';
import '../../domain/entities/user_profile.dart';
import '../models/user_profile_model.dart';

/// `GET`, `PUT` and `DELETE /profile`. Throws; the repository converts.
abstract class ProfileRemoteDataSource {
  Future<UserProfile> fetchProfile();

  Future<UserProfile> updateProfile(ProfileDraft draft);

  /// Registered clients only; answers `{status, message}` with no record.
  Future<void> deleteAccount();
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  const ProfileRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<UserProfile> fetchProfile() async {
    final response = await _client.get<UserProfile>(
      ApiEndpoints.profile,
      decoder: UserProfileModel.fromData,
    );
    return response.data;
  }

  @override
  Future<UserProfile> updateProfile(ProfileDraft draft) async {
    final response = await _client.put<UserProfile>(
      ApiEndpoints.profile,
      data: await UserProfileModel.formDataFrom(draft),
      decoder: UserProfileModel.fromData,
    );
    return response.data;
  }

  @override
  Future<void> deleteAccount() async {
    await _client.delete<Object?>(ApiEndpoints.profile);
  }
}
