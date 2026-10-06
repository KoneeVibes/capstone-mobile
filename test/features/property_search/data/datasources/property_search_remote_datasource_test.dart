import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:propertyintelmobileapp/core/network/api_client.dart';
import 'package:propertyintelmobileapp/core/network/api_endpoints.dart';
import 'package:propertyintelmobileapp/core/network/api_response.dart';
import 'package:propertyintelmobileapp/features/property_search/data/datasources/property_search_remote_datasource.dart';
import 'package:propertyintelmobileapp/features/property_search/domain/entities/invoice.dart';
import 'package:propertyintelmobileapp/features/property_search/domain/entities/property_location.dart';
import 'package:propertyintelmobileapp/features/property_search/domain/entities/search_request.dart';

import '../../property_search_fixtures.dart';

class MockApiClient extends Mock implements ApiClient {}

/// Runs the decoder the datasource passed, so the wiring is exercised.
ApiResponse<T> _decoded<T>(Invocation invocation, Object? data) {
  final decoder = invocation.namedArguments[#decoder] as T Function(Object?);
  return ApiResponse<T>(
    status: 'success',
    message: 'success',
    data: decoder(data),
  );
}

void main() {
  late MockApiClient client;
  late PropertySearchRemoteDataSourceImpl source;

  setUp(() {
    client = MockApiClient();
    source = PropertySearchRemoteDataSourceImpl(client);
  });

  test('reads the locations', () async {
    when(
      () => client.get<List<PropertyLocation>>(
        ApiEndpoints.locations,
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((invocation) async => _decoded(invocation, locationsJson));

    expect((await source.fetchLocations()).first, ikeja);
  });

  test('posts the search as multipart to /case and reads both ids', () async {
    final dir = Directory.systemTemp.createTempSync('search_ds');
    addTearDown(() => dir.deleteSync(recursive: true));
    when(
      () => client.post<SubmittedSearch>(
        any(),
        data: any(named: 'data'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((invocation) async => _decoded(invocation, createdJson));

    final submitted = await source.submit(searchRequest(dir));

    expect(submitted.trackingId, 'PI-DU2964LK');
    final captured = verify(
      () => client.post<SubmittedSearch>(
        ApiEndpoints.cases,
        data: captureAny(named: 'data'),
        decoder: any(named: 'decoder'),
      ),
    ).captured;
    expect(captured.single, isA<FormData>());
  });

  test('reads an invoice by id', () async {
    when(
      () => client.get<Invoice>(
        ApiEndpoints.invoiceById('inv-1'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((invocation) async => _decoded(invocation, invoiceJson));

    expect((await source.fetchInvoice('inv-1')).total, 11250);
  });

  test('lets a failure propagate for the repository to convert', () {
    when(
      () => client.get<Invoice>(any(), decoder: any(named: 'decoder')),
    ).thenThrow(DioException(requestOptions: RequestOptions()));

    expect(() => source.fetchInvoice('x'), throwsA(isA<DioException>()));
  });
}
