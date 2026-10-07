import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/formatting/app_formatters.dart';
import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/error/async_value_x.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_shimmer.dart';
import '../../../../shared/widgets/app_state_view.dart';
import '../../../../shared/widgets/payment_coming_soon_sheet.dart';
import '../../domain/entities/invoice.dart';
import '../providers/property_search_providers.dart';

/// "What this search costs": the new case's invoice, a way to pay it and a
/// way to follow it.
///
/// The case already exists here, unpaid, so there is no "Edit": a client
/// cannot change a filed case, and re-submitting the form would file a second.
class SearchQuoteScreen extends ConsumerWidget {
  const SearchQuoteScreen({
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoice = ref.watch(invoiceProvider(invoiceId));

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
          data: (value) => ListView(
            padding: const EdgeInsets.all(AppSizing.screenPadding),
            children: [
              if (trackingId.isNotEmpty) ...[
                _TrackingIdCard(trackingId: trackingId),
                const SizedBox(height: AppSizing.space24),
              ],
              const Text(
                'What this search costs',
                style: AppTextStyles.titleLarge,
              ),
              const SizedBox(height: AppSizing.space4),
              const Text(
                'Priced from what you entered. Nothing is charged until you '
                'approve it.',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppSizing.space16),
              _CostBreakdown(invoice: value),
              const SizedBox(height: AppSizing.space32),
              if (!value.isPaid) ...[
                AppButton(
                  label: 'Pay ${AppFormatters.currency(value.total)}',
                  onPressed: () => showPaymentComingSoonSheet(context),
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
          ),
        ),
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
  const _CostBreakdown({required this.invoice});

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
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
              const Expanded(
                child: Text('Total due', style: AppTextStyles.titleMedium),
              ),
              Text(
                AppFormatters.currency(invoice.total),
                style: AppTextStyles.titleMedium,
              ),
            ],
          ),
          if (invoice.isPaid) ...[
            const SizedBox(height: AppSizing.space8),
            Text(
              'Paid',
              style: AppTextStyles.label.copyWith(color: AppColors.success),
            ),
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
