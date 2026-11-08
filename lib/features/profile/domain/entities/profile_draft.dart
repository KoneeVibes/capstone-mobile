import 'package:equatable/equatable.dart';

import '../../../../core/utils/media_picker.dart';

/// A change to the profile. Null fields are left out of the request, so a
/// photo can be sent on its own; an empty string clears the field.
class ProfileDraft extends Equatable {
  const ProfileDraft({
    this.firstName,
    this.middleName,
    this.lastName,
    this.phone,
    this.avatar,
  });

  /// Only a new photo, as the profile's edit badge sends.
  const ProfileDraft.photo(PickedMedia this.avatar)
    : firstName = null,
      middleName = null,
      lastName = null,
      phone = null;

  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? phone;
  final PickedMedia? avatar;

  @override
  List<Object?> get props => [firstName, middleName, lastName, phone, avatar];
}
