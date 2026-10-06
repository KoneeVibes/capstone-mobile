import 'package:flutter_test/flutter_test.dart';
import 'package:propertyintelmobileapp/features/property_search/data/models/invoice_model.dart';
import 'package:propertyintelmobileapp/features/property_search/domain/entities/invoice.dart';

import '../../property_search_fixtures.dart';

void main() {
  test('decodes the live invoice', () {
    final invoice = InvoiceModel.fromData(invoiceJson);

    expect(invoice.id, 'b2516f32-14e9-41ad-9671-0b1dede6f602');
    expect(invoice.items, hasLength(3));
    expect(
      invoice.items.first,
      const InvoiceItem(
        name: 'Registry Search',
        description: 'Lagos Land Registry',
        quantity: 1,
        unitPrice: 5062,
      ),
    );
    expect(invoice.total, 11250);
    expect(invoice.currency, 'NGN');
    expect(invoice.isPaid, isFalse);
  });

  test('takes the server total over the sum of the lines', () {
    final invoice = InvoiceModel.fromData({...invoiceJson, 'totalPayable': 1});

    expect(invoice.total, 1);
  });

  test('sums the lines, quantities included, when the total is missing', () {
    final invoice = InvoiceModel.fromData({
      'id': 'inv',
      'items': [
        {'name': 'Search', 'quantity': 2, 'unitPrice': 100},
        {'name': 'Fee', 'unitPrice': 50},
      ],
    });

    expect(invoice.total, 250);
    expect(invoice.items.last.quantity, 1);
  });

  test('reads paid and refunded as nothing left to pay', () {
    for (final status in ['paid', 'refunded', 'PAID']) {
      expect(
        InvoiceModel.fromData({...invoiceJson, 'status': status}).isPaid,
        isTrue,
      );
    }
  });

  test('rejects a body with no id', () {
    expect(() => InvoiceModel.fromData({'items': []}), throwsFormatException);
    expect(() => InvoiceModel.fromData('nope'), throwsFormatException);
  });
}
