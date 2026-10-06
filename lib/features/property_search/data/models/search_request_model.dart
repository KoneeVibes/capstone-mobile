import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/utils/media_picker.dart';
import '../../../../shared/extensions/string_extensions.dart';
import '../../domain/entities/search_request.dart';

/// Wire format for `POST /case`, and its reply.
abstract final class SearchRequestModel {
  const SearchRequestModel._();

  /// Every case filed from this app says so.
  static const String source = 'mobile-app';

  /// Multipart, with list fields as repeated keys — `inquiryPurpose` twice,
  /// not `inquiryPurpose[]` — exactly as a live create accepted them.
  static Future<FormData> formDataFrom(SearchRequest request) async {
    final form = FormData()
      ..fields.addAll([
        MapEntry('applicantName', request.applicantName.trim()),
        MapEntry('applicantEmail', request.applicantEmail.trim()),
        MapEntry('applicantPhone', normalisePhone(request.applicantPhone)),
        MapEntry('propertyState', request.location.state),
        MapEntry('propertyLGA', request.location.lga),
        MapEntry('propertyCity', request.location.city),
        MapEntry('propertyAddress', request.address.trim()),
        MapEntry('propertyType', request.propertyClass.apiValue),
        for (final title in request.titleTypes)
          MapEntry('propertyTitleType', title.apiValue),
        for (final purpose in request.purposes)
          MapEntry('inquiryPurpose', purpose.apiValue),
        const MapEntry('source', source),
      ]);

    for (final (field, files) in [
      ('propertySurveyPlan', request.surveyPlans),
      ('propertyTitleDocument', request.titleDocuments),
    ]) {
      for (final file in files) {
        form.files.add(MapEntry(field, await _upload(file)));
      }
    }
    return form;
  }

  /// `{invoiceId, trackingId}` — the case itself is not returned.
  static SubmittedSearch submittedFromData(Object? data) {
    if (data is Map<String, dynamic>) {
      final trackingId = _string(data['trackingId']);
      final invoiceId = _string(data['invoiceId']);
      if (trackingId != null && invoiceId != null) {
        return SubmittedSearch(trackingId: trackingId, invoiceId: invoiceId);
      }
    }
    throw const FormatException('Create returned no tracking or invoice id.');
  }

  /// Spaces and dashes are display formatting, not part of the number.
  @visibleForTesting
  static String normalisePhone(String value) =>
      value.replaceAll(RegExp(r'[\s-]'), '');

  /// The picker already checked the extension, so the content type follows
  /// it rather than dio's guess from the path.
  @visibleForTesting
  static DioMediaType contentTypeOf(PickedMedia file) =>
      switch (file.extension) {
        'pdf' => DioMediaType('application', 'pdf'),
        'png' => DioMediaType('image', 'png'),
        _ => DioMediaType('image', 'jpeg'),
      };

  static Future<MultipartFile> _upload(PickedMedia file) =>
      MultipartFile.fromFile(
        file.path,
        filename: file.fileName,
        contentType: contentTypeOf(file),
      );

  static String? _string(Object? value) =>
      value is String ? value.nullIfBlank : null;
}
