import '../../../../shared/extensions/string_extensions.dart';
import '../../domain/entities/payment_session.dart';

/// Wire format for [PaymentSession]: `{accessCode, reference}`.
abstract final class PaymentSessionModel {
  const PaymentSessionModel._();

  static PaymentSession fromData(Object? data) {
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Payment session is not an object.');
    }
    final accessCode = _string(data['accessCode']);
    final reference = _string(data['reference']);
    if (accessCode == null || reference == null) {
      throw const FormatException('Payment session is incomplete.');
    }
    return PaymentSession(accessCode: accessCode, reference: reference);
  }

  static String? _string(Object? value) =>
      value is String ? value.nullIfBlank : null;
}
