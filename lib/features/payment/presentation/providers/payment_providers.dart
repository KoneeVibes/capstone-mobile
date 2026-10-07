import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/navigation/app_session.dart';
import '../../../../core/network/api_provider.dart';
import '../../../../core/session/cases_changed.dart';
import '../../../../core/utils/result.dart';
import '../../data/datasources/payment_remote_datasource.dart';
import '../../data/repositories/payment_repository_impl.dart';
import '../../domain/checkout_navigation.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/payment_session.dart';
import '../../domain/repositories/payment_repository.dart';

final paymentDataSourceProvider = Provider<PaymentDataSource>(
  (ref) => PaymentRemoteDataSourceImpl(ref.watch(apiClientProvider)),
);

final paymentRepositoryProvider = Provider<PaymentRepository>(
  (ref) => PaymentRepositoryImpl(ref.watch(paymentDataSourceProvider)),
);

/// An invoice, by id. Dropped when its screen closes, so coming back later
/// reads the current status.
final invoiceProvider = FutureProvider.autoDispose.family<Invoice, String>((
  ref,
  invoiceId,
) async {
  ref.watch(sessionProvider);
  final result = await ref
      .watch(paymentRepositoryProvider)
      .fetchInvoice(invoiceId);
  return result.unwrapOrThrow();
});

enum PaymentStage {
  /// Nothing in flight; Pay is available.
  idle,

  /// Re-reading the invoice and opening a transaction.
  starting,

  /// Checkout is open.
  checkingOut,

  /// Checkout closed; reading the invoice to see whether it was paid.
  confirming,

  /// Checkout finished but the invoice is not paid yet — the backend has not
  /// heard from Paystack. Pay stays hidden so nobody pays twice.
  processing,

  paid,
}

/// One invoice's payment. The invoice is the only proof of payment: whatever
/// checkout reports, [confirm] reads it back before saying "paid".
class PaymentNotifier extends Notifier<PaymentStage> {
  PaymentNotifier(this.invoiceId);

  final String invoiceId;

  PaymentRepository get _repository => ref.read(paymentRepositoryProvider);

  @override
  PaymentStage build() {
    ref.watch(sessionProvider);
    return PaymentStage.idle;
  }

  /// Opens a transaction unless the invoice is already settled, in which case
  /// it resolves to `Ok(null)`. Ignored while another step is in flight.
  Future<Result<PaymentSession?>> start() async {
    if (state != PaymentStage.idle) return const Ok(null);
    state = PaymentStage.starting;

    final invoice = await _repository.fetchInvoice(invoiceId);
    if (!ref.mounted) return const Ok(null);
    if (invoice case Err(:final failure)) {
      state = PaymentStage.idle;
      return Err(failure);
    }
    if (invoice.valueOrNull?.isPaid ?? false) {
      _markPaid();
      return const Ok(null);
    }

    final session = await _repository.startPayment(invoiceId);
    if (!ref.mounted) return const Ok(null);
    state = session.isOk ? PaymentStage.checkingOut : PaymentStage.idle;
    return session;
  }

  /// Reads the invoice after checkout closes. When checkout reported
  /// completion it keeps reading for a while, since the webhook can lag.
  Future<PaymentStage> confirm(CheckoutNavigation outcome) async {
    final completed = outcome == CheckoutNavigation.completed;
    await _readUntilPaid(
      attempts: completed ? AppConstants.paymentConfirmAttempts : 1,
    );
    if (ref.mounted && state == PaymentStage.confirming) {
      state = completed ? PaymentStage.processing : PaymentStage.idle;
    }
    return ref.mounted ? state : PaymentStage.idle;
  }

  /// One more read while [PaymentStage.processing].
  Future<void> recheck() async {
    if (state != PaymentStage.processing) return;
    await _readUntilPaid(attempts: 1);
    if (ref.mounted && state == PaymentStage.confirming) {
      state = PaymentStage.processing;
    }
  }

  Future<void> _readUntilPaid({required int attempts}) async {
    state = PaymentStage.confirming;
    for (var attempt = 0; attempt < attempts; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(AppConstants.paymentConfirmInterval);
      }
      final invoice = await _repository.fetchInvoice(invoiceId);
      if (!ref.mounted) return;
      if (invoice.valueOrNull?.isPaid ?? false) {
        _markPaid();
        return;
      }
    }
  }

  void _markPaid() {
    state = PaymentStage.paid;
    ref.invalidate(invoiceProvider(invoiceId));
    ref.read(casesChangedProvider.notifier).bump();
  }
}

final paymentProvider = NotifierProvider.autoDispose
    .family<PaymentNotifier, PaymentStage, String>(PaymentNotifier.new);
