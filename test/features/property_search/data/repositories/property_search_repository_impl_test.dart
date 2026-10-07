import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:propertyintelmobileapp/core/utils/error/failure_type.dart';
import 'package:propertyintelmobileapp/features/property_search/data/datasources/property_search_remote_datasource.dart';
import 'package:propertyintelmobileapp/features/property_search/data/repositories/property_search_repository_impl.dart';

import '../../property_search_fixtures.dart';

class MockSource extends Mock implements PropertySearchDataSource {}

void main() {
  late MockSource source;
  late PropertySearchRepositoryImpl repository;

  setUp(() {
    source = MockSource();
    repository = PropertySearchRepositoryImpl(source);
  });

  test('wraps a success', () async {
    when(source.fetchLocations).thenAnswer((_) async => locations);

    expect((await repository.fetchLocations()).valueOrNull, locations);
  });

  test('turns a malformed reply into a failure, not a throw', () async {
    when(
      source.fetchLocations,
    ).thenThrow(const FormatException('Location has no state.'));

    expect(
      (await repository.fetchLocations()).failureOrNull?.type,
      FailureType.parsing,
    );
  });
}
