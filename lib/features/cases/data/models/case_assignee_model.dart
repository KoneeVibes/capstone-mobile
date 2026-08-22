import '../../../../shared/extensions/string_extensions.dart';
import '../../domain/entities/case_assignee.dart';

/// Wire format for [CaseAssignee], decoded from a **staff** record.
///
/// There is no assignee endpoint: a case carries a bare `assigneeId`, and the
/// people it can point at are the staff list. Reading `GET /staff` here is a
/// call to an endpoint, not an import of the staff feature, so the rule that
/// features do not depend on each other still holds.
class CaseAssigneeModel extends CaseAssignee {
  const CaseAssigneeModel({
    required super.id,
    required super.firstName,
    required super.lastName,
    required this.isActive,
    super.avatarUrl,
  });

  /// Whether the account is still active.
  ///
  /// Lives on the model rather than the entity because it decides only which
  /// staff the picker offers, and never anything a screen renders. Staff delete
  /// is a soft delete, so deactivated people keep coming back from the list.
  final bool isActive;

  factory CaseAssigneeModel.fromJson(Map<String, dynamic> json) =>
      CaseAssigneeModel(
        id: _string(json['id']) ?? _string(json['_id']) ?? '',
        firstName: _string(json['firstName']) ?? '',
        lastName: _string(json['lastName']) ?? '',
        avatarUrl: _string(json['avatar']),
        isActive: (_string(json['status']) ?? '').toLowerCase() == 'active',
      );

  /// Decodes the `data` array of a staff list response.
  static List<CaseAssigneeModel> listFromJson(Object? data) {
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(CaseAssigneeModel.fromJson)
        .toList();
  }

  /// Decodes the `data` object of a single staff response.
  static CaseAssignee fromData(Object? data) {
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Expected a staff object in "data".');
    }
    return CaseAssigneeModel.fromJson(data);
  }

  static String? _string(Object? value) {
    if (value is! String) return null;
    return value.nullIfBlank;
  }
}
