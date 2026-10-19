import 'package:equatable/equatable.dart';

/// What a search costs, from `GET /invoice/{id}`. Priced server side from the
/// location and the documents named.
class Invoice extends Equatable {
  const Invoice({
    required this.id,
    required this.items,
    required this.total,
    required this.currency,
    required this.isPaid,
    this.reference,
  });

  final String id;
  final List<InvoiceItem> items;
  final num total;
  final String currency;

  /// `paid` (or `refunded`): nothing left to pay.
  final bool isPaid;

  /// Paystack's reference for the latest payment attempt; null until one is
  /// started.
  final String? reference;

  @override
  List<Object?> get props => [id, items, total, currency, isPaid, reference];
}

class InvoiceItem extends Equatable {
  const InvoiceItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.description,
  });

  final String name;
  final String? description;
  final int quantity;
  final num unitPrice;

  num get amount => unitPrice * quantity;

  @override
  List<Object?> get props => [name, description, quantity, unitPrice];
}
