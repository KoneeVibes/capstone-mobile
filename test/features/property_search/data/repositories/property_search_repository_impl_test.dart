import 'package:dio/dio.dart';
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

  test("keeps the server's wording for an unpriced location", () async {
    // The create answers 404 for a location with no rate configured.
    final options = RequestOptions(path: '/case');
    when(() => source.fetchInvoice(any())).thenThrow(
      DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response<dynamic>(
          requestOptions: options,
          statusCode: 404,
          data: {'status': 'fail', 'message': 'Invoice not found.'},
        ),
      ),
    );

    final failure = (await repository.fetchInvoice('x')).failureOrNull;

    expect(failure?.type, FailureType.notFound);
    expect(failure?.message, 'Invoice not found.');
  });

  test('turns a malformed reply into a failure, not a throw', () async {
    when(
      () => source.fetchInvoice(any()),
    ).thenThrow(const FormatException('Invoice has no id.'));

    expect(
      (await repository.fetchInvoice('x')).failureOrNull?.type,
      FailureType.parsing,
    );
  });
}
