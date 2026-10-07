import '../../../../core/utils/result.dart';
import '../entities/invoice.dart';
import '../entities/payment_session.dart';

abstract class PaymentRepository {
  Future<Result<Invoice>> fetchInvoice(String invoiceId);

  /// Asks the backend to initialise a Paystack transaction for the invoice.
  Future<Result<PaymentSession>> startPayment(String invoiceId);
}
