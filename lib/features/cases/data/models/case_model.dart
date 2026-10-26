import 'package:dio/dio.dart';

import '../../../../core/formatting/app_formatters.dart';
import '../../../../core/network/api_multipart.dart';
import '../../../../core/utils/media_picker.dart';
import '../../../../shared/extensions/string_extensions.dart';
import '../../domain/entities/case.dart';
import '../../domain/entities/case_applicant.dart';
import '../../domain/entities/case_property.dart';
import '../../domain/entities/case_status.dart';

/// Wire format for [Case].
///
/// Decoding is deliberately forgiving, for the same reason `StaffModel` is: the
/// live API returns fields outside its published schema (`_id`, `__v`) and the
/// applicant fields come from a web form, so any of them can arrive blank.
/// Nothing here throws on a missing field — a half-filled record still renders.
class CaseModel extends Case {
  const CaseModel({
    required super.id,
    super.trackingId,
    required super.applicant,
    required super.property,
    required super.status,
    super.source,
    super.inquiryPurpose,
    super.assigneeId,
    super.assignee,
    super.reports,
    super.createdAt,
    super.updatedAt,
  });

  factory CaseModel.fromJson(Map<String, dynamic> json) => CaseModel(
    // `id` is the application UUID used in paths; `_id` is the store's own key
    // and is only a fallback.
    id: _string(json['id']) ?? _string(json['_id']) ?? '',
    trackingId: _string(json['trackingId']),
    source: _string(json['source']),
    applicant: CaseApplicant(
      name: _string(json['applicantName']) ?? '',
      email: _string(json['applicantEmail']),
      phone: _string(json['applicantPhone']),
    ),
    property: CaseProperty(
      type: _string(json['propertyType']) ?? '',
      address: _string(json['propertyAddress']),
      city: _string(json['propertyCity']),
      lga: _string(json['propertyLGA']),
      state: _string(json['propertyState']),
      titleTypes: _strings(json['propertyTitleType']),
      surveyPlans: _strings(json['propertySurveyPlan']),
      titleDocuments: _strings(json['propertyTitleDocument']),
    ),
    inquiryPurpose: _strings(json['inquiryPurpose']),
    status: CaseStatus.fromApi(_string(json['status'])),
    // Null is the API's way of saying nobody holds this case.
    assigneeId: _string(json['assigneeId']),
    // Absent, not null, until a report is submitted.
    reports: _strings(json['inquiryReport']),
    createdAt: AppFormatters.parseIso(_string(json['createdAt'])),
    updatedAt: AppFormatters.parseIso(_string(json['updatedAt'])),
  );

  /// Decodes the `data` array of a list response.
  static List<Case> listFromJson(Object? data) {
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(CaseModel.fromJson)
        .toList();
  }

  /// Decodes the `data` object of a single-record response.
  static Case fromData(Object? data) {
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Expected a case object in "data".');
    }
    return CaseModel.fromJson(data);
  }

  /// The `PATCH /case/{id}` fields for an assignment. Sent as multipart, like
  /// every `PATCH /case` (see [form]).
  ///
  /// The status is sent only where assigning moves the case on: from
  /// `payment-validated`, and from `suspended`, where it lifts the suspension.
  /// Re-assigning an `accepted` case is a change of hands, not progress, and
  /// sending `assigned` alongside it would knock the case backwards through its
  /// own lifecycle. A `submitted` case never reaches here — it cannot be
  /// assigned until its payment has been validated.
  ///
  /// Visible for testing.
  static Map<String, dynamic> assignmentBody({
    required String assigneeId,
    required CaseStatus currentStatus,
  }) => <String, dynamic>{
    'assigneeId': assigneeId,
    if (currentStatus.advancesOnAssign) 'status': CaseStatus.assigned.apiValue,
  };

  /// The `PATCH /case/{id}` fields that move a case to [status].
  static Map<String, dynamic> statusBody(CaseStatus status) =>
      <String, dynamic>{'status': status.apiValue};

  /// [fields] as the multipart body `PATCH /case/{id}` documents.
  static FormData form(Map<String, dynamic> fields) => FormData.fromMap(fields);

  /// The `PUT /case/{id}` body: every file under the one repeated
  /// `inquiryReport` key.
  static Future<FormData> reportFormData(List<PickedMedia> files) async {
    final form = FormData();
    for (final file in files) {
      form.files.add(
        MapEntry('inquiryReport', await ApiMultipart.fileOf(file)),
      );
    }
    return form;
  }

  /// Reads a value as a non-blank string, collapsing `""` and non-strings to
  /// null so optional fields stay genuinely optional.
  static String? _string(Object? value) {
    if (value is! String) return null;
    return value.nullIfBlank;
  }

  /// Reads a JSON array as a list of non-blank strings, dropping anything else.
  static List<String> _strings(Object? value) {
    if (value is! List) return const [];
    return value.map(_string).whereType<String>().toList(growable: false);
  }
}
