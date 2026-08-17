import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/formatting/app_formatters.dart';
import '../../../../shared/extensions/string_extensions.dart';
import '../../domain/entities/staff.dart';
import '../../domain/entities/staff_draft.dart';
import '../../domain/entities/staff_role.dart';
import '../../domain/entities/staff_status.dart';

/// Wire format for [Staff].
///
/// Decoding is deliberately forgiving. The live API returns fields outside its
/// published schema (`_id`, `organization`, `passwordChanged`, `__v`) and sends
/// `middleName` as an empty string rather than null, so this reads only what it
/// needs and normalises blanks away.
class StaffModel extends Staff {
  const StaffModel({
    required super.id,
    required super.firstName,
    required super.lastName,
    required super.email,
    required super.role,
    required super.status,
    super.middleName,
    super.phone,
    super.avatarUrl,
    super.createdAt,
    super.updatedAt,
  });

  factory StaffModel.fromJson(Map<String, dynamic> json) => StaffModel(
    // `id` is the application ID used in paths; `_id` is the store's own key
    // and is only a fallback.
    id: _string(json['id']) ?? _string(json['_id']) ?? '',
    firstName: _string(json['firstName']) ?? '',
    middleName: _string(json['middleName']),
    lastName: _string(json['lastName']) ?? '',
    email: _string(json['email']) ?? '',
    phone: _string(json['phone']),
    avatarUrl: _string(json['avatar']),
    role: StaffRole.fromApi(_string(json['role'])),
    status: StaffStatus.fromApi(_string(json['status'])),
    createdAt: AppFormatters.parseIso(_string(json['createdAt'])),
    updatedAt: AppFormatters.parseIso(_string(json['updatedAt'])),
  );

  /// Decodes the `data` array of a list response.
  static List<Staff> listFromJson(Object? data) {
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(StaffModel.fromJson)
        .toList();
  }

  /// Decodes the `data` object of a single-record response.
  static Staff fromData(Object? data) {
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Expected a staff object in "data".');
    }
    return StaffModel.fromJson(data);
  }

  /// Builds the `multipart/form-data` body both write endpoints require.
  ///
  /// `middleName` is always sent so clearing it on the form actually clears it
  /// server-side. `avatar` is attached only when a file was picked, which
  /// matches the API's "existing avatar is retained unless a new image is
  /// uploaded" behaviour.
  static Future<FormData> formDataFrom(StaffDraft draft) async {
    final fields = <String, dynamic>{
      'firstName': draft.firstName.trim(),
      'middleName': draft.middleName?.trim() ?? '',
      'lastName': draft.lastName.trim(),
      'email': draft.email.trim(),
      'phone': draft.phone.trim(),
      'role': draft.role.apiValue,
    };

    final avatarPath = draft.avatarPath;
    if (avatarPath != null && avatarPath.isNotEmpty) {
      final (filename, mediaType) = avatarUpload(avatarPath);
      fields['avatar'] = await MultipartFile.fromFile(
        avatarPath,
        filename: filename,
        contentType: mediaType,
      );
    }

    return FormData.fromMap(fields);
  }

  /// The filename and content type to upload a picked image under.
  ///
  /// Left to itself, dio infers the type from the path, which is wrong whenever
  /// the picker re-encoded the file (an iPhone HEIC comes back as JPEG bytes).
  /// The API accepts only JPG, JPEG and PNG, so anything that is not plainly a
  /// PNG is declared JPEG — which is what the re-encode produced.
  ///
  /// Visible for testing.
  @visibleForTesting
  static (String, DioMediaType) avatarUpload(String path) {
    final isPng = path.toLowerCase().endsWith('.png');
    return isPng
        ? ('avatar.png', DioMediaType('image', 'png'))
        : ('avatar.jpg', DioMediaType('image', 'jpeg'));
  }

  /// Reads a value as a non-blank string, collapsing `""` and non-strings to
  /// null so optional fields stay genuinely optional.
  static String? _string(Object? value) {
    if (value is! String) return null;
    return value.nullIfBlank;
  }
}
