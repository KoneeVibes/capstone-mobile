import 'package:flutter_test/flutter_test.dart';
import 'package:propertyintelmobileapp/features/property_search/domain/entities/property_location.dart';

import '../../property_search_fixtures.dart';

void main() {
  test('offers each state once, sorted', () {
    expect(locations.states, ['FCT', 'Lagos']);
  });

  test('offers only the LGAs of the chosen state', () {
    expect(locations.lgasIn('Lagos'), ['Eti-Osa', 'Ikeja']);
    expect(locations.lgasIn(null), isEmpty);
  });

  test('offers only the cities of the chosen state and LGA', () {
    expect(locations.citiesIn('Lagos', 'Eti-Osa'), ['Victoria Island']);
    expect(locations.citiesIn('FCT', 'Ikeja'), isEmpty);
  });

  test('finds the priced location for a full choice, and nothing else', () {
    expect(locations.find('Lagos', 'Ikeja', 'Ikeja'), ikeja);
    expect(locations.find('Lagos', 'Ikeja', 'Abuja'), isNull);
    expect(locations.find(null, null, null), isNull);
  });
}
