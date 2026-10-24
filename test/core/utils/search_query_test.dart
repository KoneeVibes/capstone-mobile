import 'package:flutter_test/flutter_test.dart';
import 'package:propertyintelmobileapp/core/utils/search_query.dart';

void main() {
  test('trims what it sends', () {
    expect(searchQueryFrom('  PI-2RW  '), 'PI-2RW');
  });

  test('under two characters is not a search', () {
    expect(searchQueryFrom(''), isNull);
    expect(searchQueryFrom('Z'), isNull);
    expect(searchQueryFrom(' Z '), isNull);
    expect(searchQueryFrom('Zz'), 'Zz');
  });

  test('caps at the API limit of 100 characters', () {
    expect(searchQueryFrom('a' * 140), 'a' * 100);
  });
}
