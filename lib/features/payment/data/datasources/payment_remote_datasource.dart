import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/payment_session.dart';
import '../models/invoice_model.dart';
import '../models/payment_session_model.dart';

/// Network access for invoices and payments. Throws; the repository converts.
abstract class PaymentDataSource {
  /// By invoice id or case id — the endpoint resolves either to the invoice.
  Future<Invoice> fetchInvoice(String lookupId);

  /// Takes the invoice's own id only, never a case id.
  Future<PaymentSession> settle(String invoiceId);
}

class PaymentRemoteDataSourceImpl implements PaymentDataSource {
  const PaymentRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<Invoice> fetchInvoice(String lookupId) async {
    final response = await _client.get<Invoice>(
      ApiEndpoints.invoiceById(lookupId),
      decoder: InvoiceModel.fromData,
    );
    return response.data;
  }

  @override
  Future<PaymentSession> settle(String invoiceId) async {
    final response = await _client.post<PaymentSession>(
      ApiEndpoints.settleInvoice(invoiceId),
      decoder: PaymentSessionModel.fromData,
    );
    return response.data;
  }
}
