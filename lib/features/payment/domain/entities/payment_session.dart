import 'package:equatable/equatable.dart';

/// A Paystack transaction the backend has initialised for an invoice, from
/// `POST /invoice/settle/{id}`.
class PaymentSession extends Equatable {
  const PaymentSession({required this.accessCode, required this.reference});

  /// Opens Paystack's hosted checkout.
  final String accessCode;

  /// Paystack's id for this attempt; it comes back on the callback URL.
  final String reference;

  @override
  List<Object?> get props => [accessCode, reference];
}
