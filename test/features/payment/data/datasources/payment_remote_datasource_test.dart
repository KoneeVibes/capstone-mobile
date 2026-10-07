import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:propertyintelmobileapp/core/network/api_client.dart';
import 'package:propertyintelmobileapp/core/network/api_endpoints.dart';
import 'package:propertyintelmobileapp/core/network/api_response.dart';
import 'package:propertyintelmobileapp/features/payment/data/datasources/payment_remote_datasource.dart';
import 'package:propertyintelmobileapp/features/payment/domain/entities/invoice.dart';
import 'package:propertyintelmobileapp/features/payment/domain/entities/payment_session.dart';

import '../../payment_fixtures.dart';

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
  late PaymentRemoteDataSourceImpl source;

  setUp(() {
    client = MockApiClient();
    source = PaymentRemoteDataSourceImpl(client);
  });

  test('reads an invoice by id', () async {
    when(
      () =>
          client.get<Invoice>('/invoice/inv-1', decoder: any(named: 'decoder')),
    ).thenAnswer((invocation) async => _decoded(invocation, invoiceJson));

    expect((await source.fetchInvoice('inv-1')).total, 11250);
  });

  test('settles with a bodyless POST to /invoice/settle/{id}', () async {
    when(
      () => client.post<PaymentSession>(
        any(),
        data: any(named: 'data'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((invocation) async => _decoded(invocation, sessionJson));

    expect(await source.settle('inv-1'), session);
    verify(
      () => client.post<PaymentSession>(
        '/invoice/settle/inv-1',
        decoder: any(named: 'decoder'),
      ),
    ).called(1);
  });

  test('builds the checkout URL from the access code', () {
    expect(
      ApiEndpoints.paystackCheckout('97y8x8lhufrm25y'),
      'https://checkout.paystack.com/97y8x8lhufrm25y',
    );
  });

  test('lets a failure propagate for the repository to convert', () {
    when(
      () => client.post<PaymentSession>(any(), decoder: any(named: 'decoder')),
    ).thenThrow(DioException(requestOptions: RequestOptions()));

    expect(() => source.settle('x'), throwsA(isA<DioException>()));
  });
}
