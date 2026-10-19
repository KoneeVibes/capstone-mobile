import '../../../../core/utils/error/error_handler.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/payment_session.dart';
import '../../domain/repositories/payment_repository.dart';
import '../datasources/payment_remote_datasource.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  const PaymentRepositoryImpl(this._source);

  final PaymentDataSource _source;

  @override
  Future<Result<Invoice>> fetchInvoice(String lookupId) =>
      _guard(() => _source.fetchInvoice(lookupId));

  @override
  Future<Result<PaymentSession>> startPayment(String invoiceId) =>
      _guard(() => _source.settle(invoiceId));

  static Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Ok(await action());
    } on Object catch (error, stackTrace) {
      return Err(ErrorHandler.from(error, stackTrace));
    }
  }
}
