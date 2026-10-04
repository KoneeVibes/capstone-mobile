import 'package:flutter_test/flutter_test.dart';
import 'package:propertyintelmobileapp/core/utils/validators.dart';

void main() {
  group('trackingId', () {
    test('accepts a complete ID, in any case, with or without PI-', () {
      expect(Validators.trackingId('PI-URF8T7C2'), isNull);
      expect(Validators.trackingId(' pi-urf8t7c2 '), isNull);
      expect(Validators.trackingId('URF8T7C2'), isNull);
    });

    test('requires a value', () {
      expect(Validators.trackingId('  '), 'Tracking ID is required.');
      expect(Validators.trackingId(null), 'Tracking ID is required.');
    });

    test('rejects an incomplete or malformed ID', () {
      const message = 'Enter the full tracking ID, e.g. PI-URF8T7C2.';
      expect(Validators.trackingId('PI-8K4M2Q'), message);
      expect(Validators.trackingId('PI-URF8T7C2X'), message);
      expect(Validators.trackingId('XX-URF8T7C2'), message);
      expect(Validators.trackingId('PI-URF8T7C!'), message);
    });
  });

  group('password', () {
    test('requires at least eight characters', () {
      expect(Validators.password(null), 'Password is required.');
      expect(
        Validators.password('short12'),
        'Password must be at least 8 characters.',
      );
      expect(Validators.password('Password1'), isNull);
    });

    test('counts spaces, which are part of a password', () {
      expect(Validators.password('        '), isNull);
    });
  });

  group('confirmation', () {
    test('must repeat the original exactly', () {
      expect(
        Validators.confirmation('', original: 'Password1'),
        'Please repeat your password.',
      );
      expect(
        Validators.confirmation('password1', original: 'Password1'),
        "Passwords don't match.",
      );
      expect(Validators.confirmation('Password1', original: 'Password1'), isNull);
    });
  });

  group('optionalPhone', () {
    test('passes an empty field and checks a filled one', () {
      expect(Validators.optionalPhone(''), isNull);
      expect(Validators.optionalPhone('0803 411 2290'), isNull);
      expect(Validators.optionalPhone('12345'), isNotNull);
    });
  });
}
