import '../../../../shared/extensions/string_extensions.dart';

/// The two fields the dashboard reads from a `GET /case` row.
class CaseAddressModel {
  const CaseAddressModel({this.trackingId, this.address});

  factory CaseAddressModel.fromJson(Map<String, dynamic> json) {
    final street = _string(json['propertyAddress']);
    final area = [
      _string(json['propertyCity']),
      _string(json['propertyState']),
    ].whereType<String>().join(', ');

    return CaseAddressModel(
      trackingId: _string(json['trackingId']),
      address: street ?? area.nullIfBlank,
    );
  }

  final String? trackingId;
  final String? address;

  static List<CaseAddressModel> listFromJson(Object? data) {
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(CaseAddressModel.fromJson)
        .toList();
  }

  static String? _string(Object? value) {
    if (value is! String) return null;
    return value.nullIfBlank;
  }
}
