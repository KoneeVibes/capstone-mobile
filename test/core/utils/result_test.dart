import 'package:flutter_test/flutter_test.dart';
import 'package:propertyintelmobileapp/core/utils/error/app_failure.dart';
import 'package:propertyintelmobileapp/core/utils/error/failure_type.dart';
import 'package:propertyintelmobileapp/core/utils/result.dart';

const _failure = AppFailure(
  type: FailureType.notFound,
  message: "We couldn't find what you were looking for.",
  statusCode: 404,
);

void main() {
  group('Ok', () {
    const result = Ok<int>(7);

    test('reports success and exposes the value', () {
      expect(result.isOk, isTrue);
      expect(result.isErr, isFalse);
      expect(result.valueOrNull, 7);
      expect(result.failureOrNull, isNull);
    });

    test('folds through the success branch', () {
      expect(
        result.fold(onOk: (v) => 'ok $v', onErr: (f) => 'err ${f.message}'),
        'ok 7',
      );
    });

    test('maps the value', () {
      final mapped = result.map((v) => v * 2);
      expect(mapped.valueOrNull, 14);
      expect(mapped, isA<Ok<int>>());
    });

    test('unwraps without throwing', () {
      expect(result.unwrapOrThrow(), 7);
    });
  });

  group('Err', () {
    const result = Err<int>(_failure);

    test('reports failure and exposes it', () {
      expect(result.isErr, isTrue);
      expect(result.isOk, isFalse);
      expect(result.valueOrNull, isNull);
      expect(result.failureOrNull, _failure);
    });

    test('folds through the failure branch', () {
      expect(
        result.fold(onOk: (v) => 'ok $v', onErr: (f) => 'err ${f.type.name}'),
        'err notFound',
      );
    });

    test('map preserves the failure and re-types the result', () {
      final mapped = result.map((v) => v.toString());
      expect(mapped, isA<Err<String>>());
      expect(mapped.failureOrNull, _failure);
    });

    test('unwrapOrThrow throws the AppFailure itself, not a raw exception', () {
      expect(result.unwrapOrThrow, throwsA(same(_failure)));
    });
  });
}
