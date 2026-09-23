import '../../../../core/formatting/app_formatters.dart';
import '../../../../shared/extensions/string_extensions.dart';

/// Id and display name from a `GET /staff` row, for naming assignees.
class StaffNameModel {
  const StaffNameModel({required this.id, required this.name});

  factory StaffNameModel.fromJson(Map<String, dynamic> json) => StaffNameModel(
    id: _string(json['id']) ?? _string(json['_id']) ?? '',
    name: AppFormatters.fullName(
      _string(json['firstName']),
      null,
      _string(json['lastName']),
    ),
  );

  final String id;
  final String name;

  static List<StaffNameModel> listFromJson(Object? data) {
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(StaffNameModel.fromJson)
        .toList();
  }

  static String? _string(Object? value) {
    if (value is! String) return null;
    return value.nullIfBlank;
  }
}
