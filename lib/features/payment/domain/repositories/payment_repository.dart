import '../../../../core/utils/result.dart';
import '../entities/invoice.dart';
import '../entities/payment_session.dart';

abstract class PaymentRepository {
  /// Reads an invoice by its own id or by its case id — both resolve it.
  Future<Result<Invoice>> fetchInvoice(String lookupId);

  /// Asks the backend to initialise a Paystack transaction for the invoice.
  /// Takes the invoice's own id, never a case id.
  Future<Result<PaymentSession>> startPayment(String invoiceId);
}
