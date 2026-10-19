import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:propertyintelmobileapp/core/constants/app_constants.dart';
import 'package:propertyintelmobileapp/core/session/cases_changed.dart';
import 'package:propertyintelmobileapp/core/utils/error/app_failure.dart';
import 'package:propertyintelmobileapp/core/utils/error/failure_type.dart';
import 'package:propertyintelmobileapp/core/utils/result.dart';
import 'package:propertyintelmobileapp/features/payment/domain/checkout_navigation.dart';
import 'package:propertyintelmobileapp/features/payment/domain/entities/invoice.dart';
import 'package:propertyintelmobileapp/features/payment/domain/repositories/payment_repository.dart';
import 'package:propertyintelmobileapp/features/payment/presentation/providers/payment_providers.dart';

import '../../payment_fixtures.dart';

class MockRepository extends Mock implements PaymentRepository {}

const _offline = AppFailure(
  type: FailureType.network,
  message: 'No connection.',
);

void main() {
  late MockRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = MockRepository();
    container = ProviderContainer(
      overrides: [paymentRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    // Keeps the auto-dispose notifier alive between reads.
    container.listen(paymentProvider('inv'), (_, _) {});
  });

  PaymentNotifier payment() => container.read(paymentProvider('inv').notifier);
  PaymentStage stage() => container.read(paymentProvider('inv'));

  void invoiceReads(List<bool> paid) {
    final answers = paid.map((isPaid) => Ok<Invoice>(invoice(isPaid: isPaid)));
    final queue = answers.toList();
    when(() => repository.fetchInvoice('inv')).thenAnswer(
      (_) async => queue.length > 1 ? queue.removeAt(0) : queue.single,
    );
  }

  group('start', () {
    test('opens a transaction for an unpaid invoice', () async {
      invoiceReads([false]);
      when(
        () => repository.startPayment('inv'),
      ).thenAnswer((_) async => const Ok(session));

      expect((await payment().start()).valueOrNull, session);
      expect(stage(), PaymentStage.checkingOut);
    });

    test('does not open a transaction for a paid invoice', () async {
      invoiceReads([true]);

      final result = await payment().start();

      expect(result.isOk, isTrue);
      expect(result.valueOrNull, isNull);
      expect(stage(), PaymentStage.paid);
      verifyNever(() => repository.startPayment(any()));
    });

    test('returns to idle with the failure when settle fails', () async {
      invoiceReads([false]);
      when(
        () => repository.startPayment('inv'),
      ).thenAnswer((_) async => const Err(_offline));

      expect((await payment().start()).failureOrNull, _offline);
      expect(stage(), PaymentStage.idle);
    });

    test('ignores a second tap while the first is in flight', () async {
      invoiceReads([false]);
      when(
        () => repository.startPayment('inv'),
      ).thenAnswer((_) async => const Ok(session));

      final first = payment().start();
      final second = await payment().start();
      await first;

      expect(second.valueOrNull, isNull);
      verify(() => repository.startPayment('inv')).called(1);
    });

    test('settles with the invoice id when looked up by case id', () async {
      // Keyed by a case id; the lookup resolves the invoice, whose own id
      // ('inv') is what settle must be given — not the case id.
      container.listen(paymentProvider('case-1'), (_, _) {});
      when(
        () => repository.fetchInvoice('case-1'),
      ).thenAnswer((_) async => Ok(invoice()));
      when(
        () => repository.startPayment('inv'),
      ).thenAnswer((_) async => const Ok(session));

      final result = await container
          .read(paymentProvider('case-1').notifier)
          .start();

      expect(result.valueOrNull, session);
      verify(() => repository.fetchInvoice('case-1')).called(1);
      verify(() => repository.startPayment('inv')).called(1);
    });
  });

  group('confirm', () {
    test('a paid invoice marks it paid and tells the cases lists', () async {
      invoiceReads([true]);
      final before = container.read(casesChangedProvider);

      expect(
        await payment().confirm(CheckoutNavigation.completed),
        PaymentStage.paid,
      );
      expect(container.read(casesChangedProvider), before + 1);
    });

    test('a cancel that left the invoice unpaid goes back to idle', () async {
      invoiceReads([false]);

      expect(
        await payment().confirm(CheckoutNavigation.cancelled),
        PaymentStage.idle,
      );
      verify(() => repository.fetchInvoice('inv')).called(1);
    });

    test('a cancel still counts a payment that went through', () async {
      invoiceReads([true]);

      expect(
        await payment().confirm(CheckoutNavigation.cancelled),
        PaymentStage.paid,
      );
    });

    test('waits for the webhook after a completed checkout', () {
      fakeAsync((async) {
        invoiceReads([false, false, true]);
        PaymentStage? result;

        payment()
            .confirm(CheckoutNavigation.completed)
            .then((value) => result = value);
        async.elapse(AppConstants.paymentConfirmInterval * 2);

        expect(result, PaymentStage.paid);
        verify(() => repository.fetchInvoice('inv')).called(3);
      });
    });

    test('settles on processing when the webhook never comes', () {
      fakeAsync((async) {
        invoiceReads([false]);
        PaymentStage? result;

        payment()
            .confirm(CheckoutNavigation.completed)
            .then((value) => result = value);
        async.elapse(
          AppConstants.paymentConfirmInterval *
              AppConstants.paymentConfirmAttempts,
        );

        expect(result, PaymentStage.processing);
        verify(
          () => repository.fetchInvoice('inv'),
        ).called(AppConstants.paymentConfirmAttempts);
      });
    });

    test('a failed read while confirming is not taken as paid', () async {
      when(
        () => repository.fetchInvoice('inv'),
      ).thenAnswer((_) async => const Err(_offline));

      expect(
        await payment().confirm(CheckoutNavigation.cancelled),
        PaymentStage.idle,
      );
    });
  });

  group('recheck', () {
    test('stays processing while unpaid, then turns paid', () {
      fakeAsync((async) {
        invoiceReads([false]);
        payment().confirm(CheckoutNavigation.completed);
        async.elapse(
          AppConstants.paymentConfirmInterval *
              AppConstants.paymentConfirmAttempts,
        );
        expect(stage(), PaymentStage.processing);

        payment().recheck();
        async.flushMicrotasks();
        expect(stage(), PaymentStage.processing);

        invoiceReads([true]);
        payment().recheck();
        async.flushMicrotasks();
        expect(stage(), PaymentStage.paid);
      });
    });
  });
}
