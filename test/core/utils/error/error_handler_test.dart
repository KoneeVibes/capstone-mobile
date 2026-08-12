import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propertyintelmobileapp/core/utils/error/app_failure.dart';
import 'package:propertyintelmobileapp/core/utils/error/error_handler.dart';
import 'package:propertyintelmobileapp/core/utils/error/failure_type.dart';

/// Builds a DioException with a response body, as a failing HTTP call produces.
DioException _badResponse(int? statusCode, {Object? body}) {
  final options = RequestOptions(path: '/staff');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(
      requestOptions: options,
      statusCode: statusCode,
      data: body,
    ),
  );
}

DioException _ofType(DioExceptionType type, {Object? error}) => DioException(
  requestOptions: RequestOptions(path: '/staff'),
  type: type,
  error: error,
);

void main() {
  group('ErrorHandler.from — transport failures', () {
    test('maps every timeout variant to FailureType.timeout', () {
      const timeouts = [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.transformTimeout,
      ];

      for (final type in timeouts) {
        final failure = ErrorHandler.from(_ofType(type));
        expect(failure.type, FailureType.timeout, reason: type.name);
        expect(failure.message, contains('took too long'));
      }
    });

    test('maps connection and certificate errors to network', () {
      for (final type in [
        DioExceptionType.connectionError,
        DioExceptionType.badCertificate,
      ]) {
        final failure = ErrorHandler.from(_ofType(type));
        expect(failure.type, FailureType.network, reason: type.name);
        expect(failure.message, contains('offline'));
      }
    });

    test('maps cancellation to cancelled', () {
      final failure = ErrorHandler.from(_ofType(DioExceptionType.cancel));
      expect(failure.type, FailureType.cancelled);
    });

    test('treats a socket error wrapped in an unknown DioException as network', () {
      final failure = ErrorHandler.from(
        _ofType(
          DioExceptionType.unknown,
          error: const SocketException('failed host lookup'),
        ),
      );
      expect(failure.type, FailureType.network);
    });

    test('falls back to unknown for an unknown DioException with no response', () {
      final failure = ErrorHandler.from(_ofType(DioExceptionType.unknown));
      expect(failure.type, FailureType.unknown);
    });

    test('uses the response when an unknown DioException still carries one', () {
      final options = RequestOptions(path: '/staff');
      final failure = ErrorHandler.from(
        DioException(
          requestOptions: options,
          type: DioExceptionType.unknown,
          response: Response<dynamic>(
            requestOptions: options,
            statusCode: 404,
          ),
        ),
      );
      expect(failure.type, FailureType.notFound);
      expect(failure.statusCode, 404);
    });
  });

  group('ErrorHandler.from — non-Dio errors', () {
    test('maps socket and http exceptions to network', () {
      expect(
        ErrorHandler.from(const SocketException('no route')).type,
        FailureType.network,
      );
      expect(
        ErrorHandler.from(const HttpException('bad')).type,
        FailureType.network,
      );
    });

    test('maps decoding errors to parsing', () {
      expect(
        ErrorHandler.from(const FormatException('bad json')).type,
        FailureType.parsing,
      );
    });

    test('maps a TypeError from a bad cast to parsing', () {
      AppFailure? failure;
      try {
        // A model reading the wrong type out of a JSON map produces this.
        (<String, dynamic>{'id': 1}['id'] as String).length;
      } on Object catch (error, stackTrace) {
        failure = ErrorHandler.from(error, stackTrace);
      }
      expect(failure?.type, FailureType.parsing);
    });

    test('maps anything else to unknown', () {
      expect(ErrorHandler.from(Exception('boom')).type, FailureType.unknown);
      expect(ErrorHandler.from('a bare string').type, FailureType.unknown);
    });
  });

  group('ErrorHandler.from — status code assumptions', () {
    test('maps each documented status code to its own failure type', () {
      const expected = <int, FailureType>{
        400: FailureType.badRequest,
        401: FailureType.unauthorized,
        403: FailureType.forbidden,
        404: FailureType.notFound,
        408: FailureType.timeout,
        409: FailureType.conflict,
        413: FailureType.badRequest,
        415: FailureType.badRequest,
        422: FailureType.validation,
        429: FailureType.rateLimited,
        500: FailureType.server,
        502: FailureType.server,
        503: FailureType.server,
        504: FailureType.server,
      };

      expected.forEach((code, type) {
        final failure = ErrorHandler.from(_badResponse(code));
        expect(failure.type, type, reason: 'HTTP $code');
        expect(failure.statusCode, code);
        expect(failure.message, isNotEmpty);
      });
    });

    test('buckets undocumented 4xx and 5xx codes sensibly', () {
      expect(ErrorHandler.from(_badResponse(418)).type, FailureType.badRequest);
      expect(ErrorHandler.from(_badResponse(451)).type, FailureType.badRequest);
      expect(ErrorHandler.from(_badResponse(507)).type, FailureType.server);
    });

    test('falls back to unknown when there is no status code', () {
      final failure = ErrorHandler.from(_badResponse(null));
      expect(failure.type, FailureType.unknown);
      expect(failure.statusCode, isNull);
    });

    test('gives 401 a message that tells the user to sign in again', () {
      final failure = ErrorHandler.from(_badResponse(401));
      expect(failure.message, contains('sign in again'));
      expect(failure.requiresReauthentication, isTrue);
    });

    test('marks server and network failures retryable, 403 and 404 not', () {
      expect(ErrorHandler.from(_badResponse(500)).isRetryable, isTrue);
      expect(ErrorHandler.from(_badResponse(429)).isRetryable, isTrue);
      expect(ErrorHandler.from(_badResponse(403)).isRetryable, isFalse);
      expect(ErrorHandler.from(_badResponse(404)).isRetryable, isFalse);
    });
  });

  group('ErrorHandler — documented server messages', () {
    test('prefers a presentable message from the error body', () {
      final failure = ErrorHandler.from(
        _badResponse(409, body: {
          'status': 'fail',
          'message': 'A staff member with this email already exists.',
        }),
      );
      expect(
        failure.message,
        'A staff member with this email already exists.',
      );
      expect(failure.type, FailureType.conflict);
    });

    test('keeps the status-code type even when the body supplies copy', () {
      final failure = ErrorHandler.from(
        _badResponse(404, body: {'status': 'fail', 'message': 'Not found.'}),
      );
      expect(failure.type, FailureType.notFound);
    });

    test('rejects developer output and falls back to the assumption', () {
      const rejected = [
        'Exception: something broke',
        'TypeError: null is not an object',
        "type 'Null' is not a subtype of type 'String'",
        '#0      main (file:///app/main.dart:1:1)',
        '<html><body>502 Bad Gateway</body></html>',
        'Error: connect ECONNREFUSED',
        'Traceback (most recent call last)',
      ];

      for (final message in rejected) {
        final failure = ErrorHandler.from(
          _badResponse(400, body: {'message': message}),
        );
        expect(failure.message, isNot(message), reason: message);
        expect(failure.message, contains('valid'), reason: message);
      }
    });

    test('rejects empty, multi-line and overlong messages', () {
      final rejected = [
        '',
        '   ',
        'line one\nline two',
        'x' * 201,
      ];

      for (final message in rejected) {
        final failure = ErrorHandler.from(
          _badResponse(400, body: {'message': message}),
        );
        expect(failure.message, isNot(message.trim()));
      }
    });

    test('ignores a body that is not a JSON object or has no string message', () {
      expect(ErrorHandler.documentedMessage('plain text'), isNull);
      expect(ErrorHandler.documentedMessage(<String>['a', 'b']), isNull);
      expect(ErrorHandler.documentedMessage(<String, dynamic>{}), isNull);
      expect(
        ErrorHandler.documentedMessage(<String, dynamic>{'message': 42}),
        isNull,
      );
      expect(ErrorHandler.documentedMessage(null), isNull);
    });

    test('accepts a message at exactly the length limit', () {
      final message = 'a' * 200;
      expect(ErrorHandler.documentedMessage({'message': message}), message);
    });
  });

  group('ErrorHandler — safety guarantees', () {
    test('returns an existing AppFailure untouched', () {
      const original = AppFailure(
        type: FailureType.conflict,
        message: 'Already added.',
        statusCode: 409,
      );
      expect(ErrorHandler.from(original), same(original));
    });

    test('never leaks exception text into the user-facing message', () {
      final errors = <Object>[
        Exception('DioException [bad response]: internal detail'),
        StateError('Bad state: no element'),
        const FormatException('Unexpected character at offset 4'),
        _ofType(DioExceptionType.unknown, error: 'ECONNREFUSED 127.0.0.1:443'),
        _badResponse(500, body: {'message': 'Exception in thread main'}),
        _badResponse(500, body: 'PostgresError: relation does not exist'),
      ];

      for (final error in errors) {
        final message = ErrorHandler.from(error).message.toLowerCase();
        for (final leak in [
          'exception',
          'error:',
          'dio',
          'econnrefused',
          'postgres',
          'stack',
          '#0',
        ]) {
          expect(message, isNot(contains(leak)), reason: '$error');
        }
      }
    });

    test('always produces a non-empty message', () {
      final errors = <Object>[
        Exception('x'),
        _badResponse(null),
        _badResponse(999),
        _ofType(DioExceptionType.cancel),
      ];
      for (final error in errors) {
        expect(ErrorHandler.from(error).message.trim(), isNotEmpty);
      }
    });
  });

  group('AppFailure', () {
    test('compares by type, message and status code', () {
      const a = AppFailure(
        type: FailureType.notFound,
        message: 'Missing.',
        statusCode: 404,
      );
      const b = AppFailure(
        type: FailureType.notFound,
        message: 'Missing.',
        statusCode: 404,
        debugMessage: 'only differs in debug detail',
      );
      const c = AppFailure(type: FailureType.server, message: 'Missing.');

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });
}
