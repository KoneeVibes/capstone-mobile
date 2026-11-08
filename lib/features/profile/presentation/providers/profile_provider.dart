import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/navigation/app_session.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/profile_draft.dart';
import '../../domain/entities/user_profile.dart';
import 'profile_providers.dart';

/// The signed-in user's profile. One user's data, so a new session starts
/// from nothing.
class ProfileNotifier extends AsyncNotifier<UserProfile> {
  @override
  Future<UserProfile> build() async {
    if (ref.watch(sessionProvider) == null) return untilSignedIn();
    final result = await ref.read(profileRepositoryProvider).fetchProfile();
    return result.unwrapOrThrow();
  }

  /// Saves [draft] and puts the server's record straight into state.
  Future<Result<UserProfile>> save(ProfileDraft draft) async {
    final result = await ref
        .read(profileRepositoryProvider)
        .updateProfile(draft);
    if (result case Ok(:final value)) state = AsyncData(value);
    return result;
  }

  Future<Result<void>> deleteAccount() =>
      ref.read(profileRepositoryProvider).deleteAccount();
}

final profileProvider = AsyncNotifierProvider<ProfileNotifier, UserProfile>(
  ProfileNotifier.new,
);

extension SignedInProfileX on AsyncValue<UserProfile> {
  /// The loaded profile, unless it is the last user's, kept as the previous
  /// value while the next user's loads.
  UserProfile? valueFor(SessionUser? user) {
    final profile = value;
    return profile != null && profile.id == user?.id ? profile : null;
  }
}
