import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/formatting/app_formatters.dart';
import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/error/async_value_x.dart';
import '../../../../core/utils/result.dart';
import '../../../../shared/extensions/context_extensions.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_shimmer.dart';
import '../../../../shared/widgets/app_state_view.dart';
import '../../domain/checkout_navigation.dart';
import '../../domain/entities/invoice.dart';
import '../providers/payment_providers.dart';
import 'paystack_checkout_screen.dart';

/// "What this search costs": the new case's invoice, a way to pay it and a
/// way to follow it.
///
/// The case already exists here, unpaid, so there is no "Edit": a client
/// cannot change a filed case, and re-submitting the form would file a second.
class InvoiceScreen extends ConsumerWidget {
  const InvoiceScreen({
    required this.invoiceId,
    required this.trackingId,
    required this.trackRouteName,
    super.key,
  });

  final String invoiceId;

  /// Empty when the route was opened without it.
  final String trackingId;

  /// Takes a `trackingId` path parameter.
  final String trackRouteName;

  Future<void> _pay(BuildContext context, WidgetRef ref) async {
    final payment = ref.read(paymentProvider(invoiceId).notifier);
    final started = await payment.start();
    if (!context.mounted) return;

    switch (started) {
      case Err(:final failure):
        context.showFailure(failure);
      case Ok(value: null):
        // Already paid; the screen redraws from the invoice.
        break;
      case Ok(:final value?):
        final outcome = await Navigator.of(context, rootNavigator: true)
            .push<CheckoutNavigation>(
              MaterialPageRoute(
                fullscreenDialog: true,
                builder: (_) => PaystackCheckoutScreen(session: value),
              ),
            );
        final stage = await payment.confirm(
          outcome ?? CheckoutNavigation.cancelled,
        );
        if (context.mounted && stage == PaymentStage.idle) {
          context.showMessage('Payment not completed. You can pay any time.');
        }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoice = ref.watch(invoiceProvider(invoiceId));
    final stage = ref.watch(paymentProvider(invoiceId));

    return Scaffold(
      appBar: AppBar(title: const Text('Search submitted')),
      body: SafeArea(
        child: invoice.when2(
          loading: () => const _QuoteSkeleton(),
          error: (failure) => AppStateView.failure(
            failure: failure,
            onRetry: failure.isRetryable
                ? () => ref.invalidate(invoiceProvider(invoiceId))
                : null,
          ),
          data: (value) {
            final isPaid = value.isPaid || stage == PaymentStage.paid;
            final isBusy =
                stage == PaymentStage.starting ||
                stage == PaymentStage.checkingOut ||
                stage == PaymentStage.confirming;

            return ListView(
              padding: const EdgeInsets.all(AppSizing.screenPadding),
              children: [
                if (trackingId.isNotEmpty && !isPaid) ...[
                  _TrackingIdCard(trackingId: trackingId),
                  const SizedBox(height: AppSizing.space24),
                ],
                if (isPaid) ...[
                  _NoticeCard(
                    icon: Icons.check_circle,
                    color: AppColors.success,
                    background: AppColors.successSoft,
                    title: 'Payment received',
                    message: trackingId.isNotEmpty
                        ? 'Your search $trackingId is now with our team.'
                        : 'This search is now with our team.',
                  ),
                  const SizedBox(height: AppSizing.space24),
                ],
                if (stage == PaymentStage.processing) ...[
                  const _NoticeCard(
                    icon: Icons.hourglass_top,
                    color: AppColors.warning,
                    background: AppColors.warningSoft,
                    title: 'Confirming your payment',
                    message:
                        'Paystack is still confirming it. Your case updates '
                        'on its own once it does, so there is no need to pay '
                        'again.',
                  ),
                  const SizedBox(height: AppSizing.space24),
                ],
                const Text(
                  'What this search costs',
                  style: AppTextStyles.titleLarge,
                ),
                const SizedBox(height: AppSizing.space4),
                Text(
                  isPaid
                      ? 'Priced from what you entered.'
                      : 'Priced from what you entered. Nothing is charged '
                            'until you approve it.',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: AppSizing.space16),
                _CostBreakdown(invoice: value, isPaid: isPaid),
                const SizedBox(height: AppSizing.space32),
                if (stage == PaymentStage.processing) ...[
                  AppButton(
                    label: 'Check again',
                    onPressed: () =>
                        ref.read(paymentProvider(invoiceId).notifier).recheck(),
                  ),
                  const SizedBox(height: AppSizing.space12),
                ] else if (!isPaid) ...[
                  AppButton(
                    label: 'Pay ${AppFormatters.currency(value.total)}',
                    isLoading: isBusy,
                    onPressed: () => _pay(context, ref),
                  ),
                  const SizedBox(height: AppSizing.space12),
                ],
                if (trackingId.isNotEmpty)
                  AppButton(
                    label: 'Track this request',
                    variant: AppButtonVariant.secondary,
                    icon: Icons.arrow_forward,
                    onPressed: () => context.goNamed(
                      trackRouteName,
                      pathParameters: {'trackingId': trackingId},
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.icon,
    required this.color,
    required this.background,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizing.space16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: AppSizing.iconLg),
          const SizedBox(width: AppSizing.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleSmall),
                const SizedBox(height: AppSizing.space2),
                Text(message, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingIdCard extends StatelessWidget {
  const _TrackingIdCard({required this.trackingId});

  final String trackingId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizing.space16),
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: AppColors.success,
            size: AppSizing.iconLg,
          ),
          const SizedBox(width: AppSizing.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your tracking ID', style: AppTextStyles.bodySmall),
                const SizedBox(height: AppSizing.space2),
                SelectableText(trackingId, style: AppTextStyles.titleMedium),
                const SizedBox(height: AppSizing.space2),
                const Text(
                  'Keep it to check on this search at any time.',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CostBreakdown extends StatelessWidget {
  const _CostBreakdown({required this.invoice, required this.isPaid});

  final Invoice invoice;

  /// Ahead of [Invoice.isPaid] for the moment between confirmation and the
  /// invoice being re-read.
  final bool isPaid;

  @override
  Widget build(BuildContext context) {
    final reference = invoice.reference;

    return Container(
      padding: const EdgeInsets.all(AppSizing.space16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Cost breakdown', style: AppTextStyles.titleSmall),
          const SizedBox(height: AppSizing.space8),
          for (final item in invoice.items) ...[
            _CostRow(item: item),
            const Divider(),
          ],
          const SizedBox(height: AppSizing.space8),
          Row(
            children: [
              Expanded(
                child: Text(
                  isPaid ? 'Total paid' : 'Total due',
                  style: AppTextStyles.titleMedium,
                ),
              ),
              Text(
                AppFormatters.currency(invoice.total),
                style: AppTextStyles.titleMedium,
              ),
            ],
          ),
          if (isPaid) ...[
            const SizedBox(height: AppSizing.space8),
            Text(
              'Paid',
              style: AppTextStyles.label.copyWith(color: AppColors.success),
            ),
            if (reference != null) ...[
              const SizedBox(height: AppSizing.space4),
              SelectableText(
                'Reference $reference',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _CostRow extends StatelessWidget {
  const _CostRow({required this.item});

  final InvoiceItem item;

  @override
  Widget build(BuildContext context) {
    final description = item.description;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizing.space8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.quantity > 1
                      ? '${item.name} × ${item.quantity}'
                      : item.name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                if (description != null)
                  Text(description, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: AppSizing.space12),
          Text(
            AppFormatters.currency(item.amount),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Mirrors the loaded layout: tracking card, heading, three cost rows.
class _QuoteSkeleton extends StatelessWidget {
  const _QuoteSkeleton();

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView(
        padding: const EdgeInsets.all(AppSizing.screenPadding),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          const AppShimmerBox(height: AppSizing.space48 + AppSizing.space32),
          const SizedBox(height: AppSizing.space24),
          const AppShimmerBox(
            width: AppSizing.space48 * 4,
            height: AppSizing.space20,
          ),
          const SizedBox(height: AppSizing.space8),
          const AppShimmerBox(height: AppSizing.space12),
          const SizedBox(height: AppSizing.space16),
          for (var i = 0; i < 4; i++) ...[
            const AppShimmerBox(height: AppSizing.space32),
            const SizedBox(height: AppSizing.space12),
          ],
          const SizedBox(height: AppSizing.space20),
          const AppShimmerBox(height: AppSizing.buttonHeight),
        ],
      ),
    );
  }
}
