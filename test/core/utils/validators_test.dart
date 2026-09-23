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
}
