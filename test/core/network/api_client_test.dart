import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:propertyintelmobileapp/core/network/api_client.dart';
import 'package:propertyintelmobileapp/core/network/api_response.dart';
import 'package:propertyintelmobileapp/core/utils/error/error_handler.dart';
import 'package:propertyintelmobileapp/core/utils/error/failure_type.dart';

class MockDio extends Mock implements Dio {}

/// A single staff record in the shape the API documents.
const _staffJson = {
  'id': '7c8d3a65-6c09-489f-96d5-0f8454b5a8be',
  'firstName': 'Ada',
  'middleName': 'Grace',
  'lastName': 'Okafor',
  'email': 'ada.okafor@example.com',
  'phone': '+2348012345678',
  'avatar': null,
  'role': 'manager',
  'type': 'staff',
  'status': 'active',
  'createdAt': '2026-08-12T18:11:45.542Z',
  'updatedAt': '2026-08-12T18:11:45.542Z',
};

void main() {
  late MockDio dio;
  late ApiClient client;

  setUpAll(() {
    registerFallbackValue(Options());
    registerFallbackValue(CancelToken());
  });

  setUp(() {
    dio = MockDio();
    client = ApiClient(dio);
  });

  /// Makes the mocked Dio answer with [data] at [statusCode].
  void stubResponse(Object? data, {int statusCode = 200}) {
    final options = RequestOptions(path: '/staff');
    when(
      () => dio.request<dynamic>(
        any(),
        data: any(named: 'data'),
        queryParameters: any(named: 'queryParameters'),
        cancelToken: any(named: 'cancelToken'),
        options: any(named: 'options'),
      ),
    ).thenAnswer(
      (_) async => Response<dynamic>(
        requestOptions: options,
        statusCode: statusCode,
        data: data,
      ),
    );
  }

  group('envelope unwrapping', () {
    test('parses a success envelope and applies the decoder', () async {
      stubResponse({
        'status': 'success',
        'message': 'success',
        'data': [_staffJson],
      });

      final response = await client.get<List<String>>(
        '/staff',
        decoder: (data) => (data! as List)
            .map((e) => (e as Map<String, dynamic>)['email'] as String)
            .toList(),
      );

      expect(response.isSuccess, isTrue);
      expect(response.message, 'success');
      expect(response.data, ['ada.okafor@example.com']);
    });

    test('hands back raw data when no decoder is supplied', () async {
      stubResponse({
        'status': 'success',
        'message': 'success',
        'data': _staffJson,
      });

      final response = await client.get<dynamic>('/staff/1');
      expect((response.data as Map)['role'], 'manager');
    });

    test('parses pagination meta', () async {
      stubResponse({
        'status': 'success',
        'message': 'success',
        'data': [_staffJson],
        'meta': {'page': 1, 'perPage': 10, 'total': 25, 'totalPages': 3},
      });

      final response = await client.get<dynamic>('/staff');
      final meta = response.meta;

      expect(meta, isNotNull);
      expect(meta!.page, 1);
      expect(meta.perPage, 10);
      expect(meta.total, 25);
      expect(meta.totalPages, 3);
      expect(meta.hasNextPage, isTrue);
      expect(meta.nextPage, 2);
    });

    test('leaves meta null when the response has none', () async {
      stubResponse({'status': 'success', 'message': 'ok', 'data': _staffJson});

      final response = await client.get<dynamic>('/staff/1');
      expect(response.meta, isNull);
    });

    test('reports no next page on the final page', () async {
      stubResponse({
        'status': 'success',
        'message': 'ok',
        'data': <dynamic>[],
        'meta': {'page': 3, 'perPage': 10, 'total': 25, 'totalPages': 3},
      });

      final response = await client.get<dynamic>('/staff');
      expect(response.meta!.hasNextPage, isFalse);
    });
  });

  group('failure paths', () {
    test('throws when the envelope reports failure on HTTP 200', () async {
      stubResponse({
        'status': 'fail',
        'message': 'A staff member with this email already exists.',
      });

      await expectLater(
        client.post<dynamic>('/staff'),
        throwsA(isA<DioException>()),
      );
    });

    test('throws on a non-2xx response that Dio let through', () async {
      stubResponse(
        {'status': 'fail', 'message': 'Staff member not found.'},
        statusCode: 404,
      );

      await expectLater(
        client.get<dynamic>('/staff/missing'),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'statusCode',
            404,
          ),
        ),
      );
    });

    test('throws when the body is not a JSON object', () async {
      stubResponse('<html>502 Bad Gateway</html>');

      await expectLater(
        client.get<dynamic>('/staff'),
        throwsA(isA<DioException>()),
      );
    });

    test('a thrown envelope failure carries the documented message through '
        'ErrorHandler', () async {
      stubResponse(
        {
          'status': 'fail',
          'message': 'A staff member with this email already exists.',
        },
        statusCode: 409,
      );

      try {
        await client.post<dynamic>('/staff');
        fail('expected a DioException');
      } on Object catch (error, stackTrace) {
        final failure = ErrorHandler.from(error, stackTrace);
        expect(failure.type, FailureType.conflict);
        expect(
          failure.message,
          'A staff member with this email already exists.',
        );
        expect(failure.statusCode, 409);
      }
    });

    test('an unparseable body surfaces as a safe message, not raw HTML',
        () async {
      stubResponse('<html>502 Bad Gateway</html>');

      try {
        await client.get<dynamic>('/staff');
        fail('expected a DioException');
      } on Object catch (error, stackTrace) {
        final failure = ErrorHandler.from(error, stackTrace);
        expect(failure.message, isNot(contains('html')));
        expect(failure.message, isNotEmpty);
      }
    });
  });

  group('request dispatch', () {
    test('sends the right method, query parameters and body', () async {
      stubResponse({'status': 'success', 'message': 'ok', 'data': null});

      await client.post<dynamic>(
        '/staff',
        data: {'firstName': 'Ada'},
        queryParameters: {'page': 2},
      );

      final captured = verify(
        () => dio.request<dynamic>(
          captureAny(),
          data: captureAny(named: 'data'),
          queryParameters: captureAny(named: 'queryParameters'),
          cancelToken: any(named: 'cancelToken'),
          options: captureAny(named: 'options'),
        ),
      ).captured;

      expect(captured[0], '/staff');
      expect(captured[1], {'firstName': 'Ada'});
      expect(captured[2], {'page': 2});
      expect((captured[3] as Options).method, 'POST');
    });

    test('each verb sends its own method', () async {
      stubResponse({'status': 'success', 'message': 'ok', 'data': null});

      await client.get<dynamic>('/staff');
      await client.put<dynamic>('/staff/1');
      await client.patch<dynamic>('/staff/1');
      await client.delete<dynamic>('/staff/1');

      final methods = verify(
        () => dio.request<dynamic>(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          cancelToken: any(named: 'cancelToken'),
          options: captureAny(named: 'options'),
        ),
      ).captured.map((o) => (o as Options).method).toList();

      expect(methods, ['GET', 'PUT', 'PATCH', 'DELETE']);
    });
  });

  group('PageMeta', () {
    test('coerces numeric strings and fills sensible defaults', () {
      final meta = PageMeta.fromJson({
        'page': '2',
        'perPage': 10.0,
        'total': null,
        'totalPages': 4,
      });

      expect(meta.page, 2);
      expect(meta.perPage, 10);
      expect(meta.total, 0);
      expect(meta.totalPages, 4);
    });

    test('defaults an empty meta block rather than throwing', () {
      final meta = PageMeta.fromJson({});
      expect(meta.page, 1);
      expect(meta.totalPages, 1);
      expect(meta.hasNextPage, isFalse);
    });
  });
}
