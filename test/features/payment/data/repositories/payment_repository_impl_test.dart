import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:propertyintelmobileapp/core/utils/error/failure_type.dart';
import 'package:propertyintelmobileapp/features/payment/data/datasources/payment_remote_datasource.dart';
import 'package:propertyintelmobileapp/features/payment/data/repositories/payment_repository_impl.dart';

import '../../payment_fixtures.dart';

class MockSource extends Mock implements PaymentDataSource {}

DioException _http(int status, String message) {
  final options = RequestOptions(path: '/invoice/settle/x');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(
      requestOptions: options,
      statusCode: status,
      data: {'status': 'fail', 'message': message},
    ),
  );
}

void main() {
  late MockSource source;
  late PaymentRepositoryImpl repository;

  setUp(() {
    source = MockSource();
    repository = PaymentRepositoryImpl(source);
  });

  test('wraps a session', () async {
    when(() => source.settle('inv')).thenAnswer((_) async => session);

    expect((await repository.startPayment('inv')).valueOrNull, session);
  });

  test("keeps the server's wording when settle fails", () async {
    when(
      () => source.settle(any()),
    ).thenThrow(_http(404, 'Invoice not found.'));

    final failure = (await repository.startPayment('x')).failureOrNull;

    expect(failure?.type, FailureType.notFound);
    expect(failure?.message, 'Invoice not found.');
  });

  test('turns a malformed invoice into a failure, not a throw', () async {
    when(
      () => source.fetchInvoice(any()),
    ).thenThrow(const FormatException('Invoice has no id.'));

    expect(
      (await repository.fetchInvoice('x')).failureOrNull?.type,
      FailureType.parsing,
    );
  });
}
