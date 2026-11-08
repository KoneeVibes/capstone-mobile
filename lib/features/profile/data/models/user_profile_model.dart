import 'package:dio/dio.dart';

import '../../../../core/network/api_multipart.dart';
import '../../../../shared/extensions/string_extensions.dart';
import '../../domain/entities/profile_draft.dart';
import '../../domain/entities/user_profile.dart';

/// Wire format for [UserProfile]. Forgiving: blanks become null and unknown
/// keys (`_id`) are ignored.
class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.id,
    required super.firstName,
    required super.lastName,
    super.middleName,
    super.phone,
    super.avatarUrl,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) =>
      UserProfileModel(
        id: _string(json['id']) ?? _string(json['_id']) ?? '',
        firstName: _string(json['firstName']) ?? '',
        middleName: _string(json['middleName']),
        lastName: _string(json['lastName']) ?? '',
        phone: _string(json['phone']),
        avatarUrl: _string(json['avatar']),
      );

  /// Decodes the `data` object of a profile response.
  static UserProfile fromData(Object? data) {
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Expected a profile object in "data".');
    }
    return UserProfileModel.fromJson(data);
  }

  /// The multipart body `PUT /profile` takes; only the fields [draft] sets.
  static Future<FormData> formDataFrom(ProfileDraft draft) async {
    final fields = <String, dynamic>{
      if (draft.firstName case final value?) 'firstName': value.trim(),
      if (draft.middleName case final value?) 'middleName': value.trim(),
      if (draft.lastName case final value?) 'lastName': value.trim(),
      if (draft.phone case final value?) 'phone': value.trim(),
    };
    if (draft.avatar case final avatar?) {
      fields['avatar'] = await ApiMultipart.fileOf(avatar);
    }
    return FormData.fromMap(fields);
  }

  static String? _string(Object? value) =>
      value is String ? value.nullIfBlank : null;
}
