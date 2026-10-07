import '../../../../shared/extensions/string_extensions.dart';
import '../../domain/entities/property_location.dart';

/// Wire format for [PropertyLocation]: `{state, lga, city, rate}`.
abstract final class PropertyLocationModel {
  const PropertyLocationModel._();

  /// Rows missing a place name or a numeric rate are dropped: the form could
  /// not offer them, and the server could not price them.
  static List<PropertyLocation> listFromJson(Object? data) {
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(_fromJson)
        .whereType<PropertyLocation>()
        .toList();
  }

  static PropertyLocation? _fromJson(Map<String, dynamic> json) {
    final state = _string(json['state']);
    final lga = _string(json['lga']);
    final city = _string(json['city']);
    final rate = json['rate'];
    if (state == null || lga == null || city == null || rate is! num) {
      return null;
    }
    return PropertyLocation(state: state, lga: lga, city: city, rate: rate);
  }

  static String? _string(Object? value) =>
      value is String ? value.nullIfBlank : null;
}
