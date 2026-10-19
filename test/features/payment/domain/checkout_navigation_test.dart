import 'package:flutter_test/flutter_test.dart';
import 'package:propertyintelmobileapp/features/payment/domain/checkout_navigation.dart';

const _reference = 'T354204543241066';

CheckoutNavigation _of(String url) =>
    CheckoutNavigation.of(Uri.parse(url), reference: _reference);

void main() {
  test('lets checkout and bank pages load', () {
    expect(
      _of('https://checkout.paystack.com/97y8x8lhufrm25y'),
      CheckoutNavigation.proceed,
    );
    expect(
      _of('https://acs.somebank.com/3ds?session=abc'),
      CheckoutNavigation.proceed,
    );
  });

  test('recognises our reference on any callback host', () {
    expect(
      _of(
        'https://propertyintel.example/pay/done?trxref=$_reference'
        '&reference=$_reference',
      ),
      CheckoutNavigation.completed,
    );
    expect(
      _of('https://hello.pstk.xyz/callback?reference=$_reference'),
      CheckoutNavigation.completed,
    );
  });

  test("ignores another attempt's reference and Paystack's own pages", () {
    expect(
      _of('https://propertyintel.example/pay/done?reference=T1'),
      CheckoutNavigation.proceed,
    );
    expect(
      _of('https://checkout.paystack.com/abc?reference=$_reference'),
      CheckoutNavigation.proceed,
    );
  });

  test('reads Paystack closing the checkout as a cancel', () {
    expect(
      _of('https://standard.paystack.co/close'),
      CheckoutNavigation.cancelled,
    );
  });

  test("reads Paystack's Cancel from the messages it posts itself", () {
    // Seen live on 7 Oct 2026: Cancel posts both forms, then history.back().
    expect(
      CheckoutNavigation.ofPageMessage('close'),
      CheckoutNavigation.cancelled,
    );
    expect(
      CheckoutNavigation.ofPageMessage({'event': 'close'}),
      CheckoutNavigation.cancelled,
    );
    expect(
      CheckoutNavigation.ofPageMessage({'event': 'success'}),
      CheckoutNavigation.completed,
    );
  });

  test('ignores page messages that do not end checkout', () {
    expect(CheckoutNavigation.ofPageMessage({'event': 'loaded'}), isNull);
    expect(CheckoutNavigation.ofPageMessage(42), isNull);
    expect(CheckoutNavigation.ofPageMessage(null), isNull);
  });

  test('hands non-web links to the device', () {
    expect(
      _of('intent://pay#Intent;scheme=bank;end'),
      CheckoutNavigation.external,
    );
    expect(_of('tel:*737*000#'), CheckoutNavigation.external);
  });
}
