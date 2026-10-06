import '../../../../shared/extensions/string_extensions.dart';
import '../../domain/entities/invoice.dart';

/// Wire format for [Invoice].
abstract final class InvoiceModel {
  const InvoiceModel._();

  static Invoice fromData(Object? data) {
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invoice is not an object.');
    }
    final id = _string(data['id']);
    if (id == null) throw const FormatException('Invoice has no id.');

    final items = data['items'] is List
        ? (data['items'] as List)
              .whereType<Map<String, dynamic>>()
              .map(_item)
              .whereType<InvoiceItem>()
              .toList()
        : const <InvoiceItem>[];
    final total = data['totalPayable'];
    final status = _string(data['status'])?.toLowerCase();

    return Invoice(
      id: id,
      items: items,
      // The server computes the total; summing the items is only a fallback.
      total: total is num
          ? total
          : items.fold<num>(0, (sum, item) => sum + item.amount),
      currency: _string(data['currency']) ?? 'NGN',
      isPaid: status == 'paid' || status == 'refunded',
    );
  }

  static InvoiceItem? _item(Map<String, dynamic> json) {
    final name = _string(json['name']);
    final unitPrice = json['unitPrice'];
    if (name == null || unitPrice is! num) return null;
    final quantity = json['quantity'];
    return InvoiceItem(
      name: name,
      description: _string(json['description']),
      quantity: quantity is num && quantity >= 1 ? quantity.toInt() : 1,
      unitPrice: unitPrice,
    );
  }

  static String? _string(Object? value) =>
      value is String ? value.nullIfBlank : null;
}
