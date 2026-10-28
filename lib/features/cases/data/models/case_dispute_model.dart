import 'package:dio/dio.dart';

import '../../../../core/formatting/app_formatters.dart';
import '../../../../core/network/api_multipart.dart';
import '../../../../core/utils/media_picker.dart';
import '../../../../shared/extensions/string_extensions.dart';
import '../../domain/entities/case_dispute.dart';

/// Wire format for [CaseDispute]. Forgiving, like `CaseModel`: a missing field
/// decodes to a blank, never a throw.
class CaseDisputeModel extends CaseDispute {
  const CaseDisputeModel({
    required super.id,
    required super.caseId,
    required super.title,
    required super.description,
    required super.status,
    super.attachments,
    super.rejectionNote,
    super.createdAt,
    super.updatedAt,
  });

  factory CaseDisputeModel.fromJson(Map<String, dynamic> json) =>
      CaseDisputeModel(
        id: _string(json['id']) ?? _string(json['_id']) ?? '',
        caseId: _string(json['caseId']) ?? '',
        title: _string(json['title']) ?? '',
        description: _string(json['description']) ?? '',
        status: DisputeStatus.fromApi(_string(json['status'])),
        // Null, per the spec, when no evidence was attached.
        attachments: _strings(json['attachment']),
        rejectionNote: _string(json['rejectionNote']),
        createdAt: AppFormatters.parseIso(_string(json['createdAt'])),
        updatedAt: AppFormatters.parseIso(_string(json['updatedAt'])),
      );

  /// Decodes the `data` array of a list response.
  static List<CaseDispute> listFromJson(Object? data) {
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(CaseDisputeModel.fromJson)
        .toList();
  }

  /// Decodes the `data` object of a single-record response.
  static CaseDispute fromData(Object? data) {
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Expected a dispute object in "data".');
    }
    return CaseDisputeModel.fromJson(data);
  }

  /// The `POST /dispute` body: the fields, and every file under the one
  /// repeated `attachment` key.
  static Future<FormData> raiseFormData({
    required String caseId,
    required String title,
    required String description,
    required List<PickedMedia> attachments,
  }) async {
    final form = FormData.fromMap({
      'caseId': caseId,
      'title': title.trim(),
      'description': description.trim(),
    });
    for (final file in attachments) {
      form.files.add(MapEntry('attachment', await ApiMultipart.fileOf(file)));
    }
    return form;
  }

  static String? _string(Object? value) {
    if (value is! String) return null;
    return value.nullIfBlank;
  }

  static List<String> _strings(Object? value) {
    if (value is! List) return const [];
    return value.map(_string).whereType<String>().toList(growable: false);
  }
}
