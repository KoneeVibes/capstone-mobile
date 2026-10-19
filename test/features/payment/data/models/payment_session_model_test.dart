import 'package:flutter_test/flutter_test.dart';
import 'package:propertyintelmobileapp/features/payment/data/models/payment_session_model.dart';

import '../../payment_fixtures.dart';

void main() {
  test('decodes the live settle reply', () {
    expect(PaymentSessionModel.fromData(sessionJson), session);
  });

  test('rejects a reply missing either field', () {
    expect(
      () => PaymentSessionModel.fromData({'accessCode': 'code'}),
      throwsFormatException,
    );
    expect(
      () => PaymentSessionModel.fromData({...sessionJson, 'accessCode': ' '}),
      throwsFormatException,
    );
    expect(() => PaymentSessionModel.fromData(null), throwsFormatException);
  });
}
