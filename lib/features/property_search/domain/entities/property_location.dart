import 'package:equatable/equatable.dart';

/// One priced place a search can be filed for, from `GET /misc/location`.
///
/// The list is short and fixed server side; a case anywhere else is refused
/// with a 404, so the form only offers these.
class PropertyLocation extends Equatable {
  const PropertyLocation({
    required this.state,
    required this.lga,
    required this.city,
    required this.rate,
  });

  final String state;
  final String lga;
  final String city;

  /// The location's base rate in naira. The invoice is priced from it.
  final num rate;

  @override
  List<Object?> get props => [state, lga, city, rate];
}

/// The State → LGA → City cascade over the location list.
extension PropertyLocationsX on List<PropertyLocation> {
  List<String> get states => _sortedUnique(map((value) => value.state));

  List<String> lgasIn(String? state) => _sortedUnique(
    where((value) => value.state == state).map((value) => value.lga),
  );

  List<String> citiesIn(String? state, String? lga) => _sortedUnique(
    where(
      (value) => value.state == state && value.lga == lga,
    ).map((value) => value.city),
  );

  PropertyLocation? find(String? state, String? lga, String? city) => where(
    (value) => value.state == state && value.lga == lga && value.city == city,
  ).firstOrNull;

  static List<String> _sortedUnique(Iterable<String> values) =>
      values.toSet().toList()..sort();
}
