import 'package:flutter_test/flutter_test.dart';
import 'package:propertyintelmobileapp/features/property_search/data/models/property_location_model.dart';

import '../../property_search_fixtures.dart';

void main() {
  test('decodes the live rows', () {
    final decoded = PropertyLocationModel.listFromJson(locationsJson);

    expect(decoded, hasLength(4));
    expect(decoded.first, ikeja);
  });

  test('drops rows the form could not offer or the server could not price', () {
    final decoded = PropertyLocationModel.listFromJson([
      {'state': 'Lagos', 'lga': 'Ikeja', 'city': ' ', 'rate': 4500},
      {'state': 'Lagos', 'lga': 'Ikeja', 'city': 'Ikeja', 'rate': '4500'},
      'not a row',
    ]);

    expect(decoded, isEmpty);
  });

  test('reads anything but a list as no locations', () {
    expect(PropertyLocationModel.listFromJson(null), isEmpty);
  });
}
