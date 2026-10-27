import 'package:flutter/material.dart';

import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../domain/entities/case_dispute.dart';
import 'case_document_tile.dart';

/// "Property Update": the case's report and the disputes raised on it.
///
/// The caller decides whether the report may be shown: clients see it only
/// once the case is closed (ADR 0019).
class CasePropertyUpdate extends StatelessWidget {
  const CasePropertyUpdate({
    required this.disputes,
    required this.onView,
    super.key,
    this.reports = const [],
    this.onRaise,
  });

  /// The report's file URLs; the Report part is left out when empty.
  final List<String> reports;

  final List<CaseDispute> disputes;
  final ValueChanged<CaseDispute> onView;

  /// Set for a client who may raise a dispute; staff only answer them.
  final VoidCallback? onRaise;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSizing.radiusLg);
    final onRaise = this.onRaise;
    final showDisputes = disputes.isNotEmpty || onRaise != null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: radius,
        border: Border.all(
          color: AppColors.border,
          width: AppSizing.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizing.space16,
              vertical: AppSizing.space12,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppSizing.radiusLg),
              ),
            ),
            child: const Text('Property Update', style: AppTextStyles.label),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSizing.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (reports.isNotEmpty) ...[
                  const Text('Report', style: AppTextStyles.label),
                  const SizedBox(height: AppSizing.space12),
                  CaseDocumentGrid(
                    documents: CaseDocumentGrid.numbered('Report', reports),
                  ),
                  if (showDisputes) ...[
                    const SizedBox(height: AppSizing.space16),
                    const Divider(),
                    const SizedBox(height: AppSizing.space16),
                  ],
                ],
                if (showDisputes)
                  const Text('Dispute', style: AppTextStyles.label),
                if (onRaise != null) ...[
                  const SizedBox(height: AppSizing.space2),
                  const Text(
                    'Add a dispute if you have a concern with the search.',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
                for (final dispute in disputes) ...[
                  const SizedBox(height: AppSizing.space12),
                  _DisputeSummary(dispute: dispute),
                  const SizedBox(height: AppSizing.space12),
                  AppButton(
                    label: 'View dispute',
                    variant: AppButtonVariant.secondary,
                    onPressed: () => onView(dispute),
                  ),
                ],
                if (onRaise != null && disputes.isEmpty) ...[
                  const SizedBox(height: AppSizing.space12),
                  AppButton(
                    label: 'Raise dispute',
                    icon: Icons.add,
                    variant: AppButtonVariant.secondary,
                    onPressed: onRaise,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A dispute's status icon, title and opening lines.
class _DisputeSummary extends StatelessWidget {
  const _DisputeSummary({required this.dispute});

  final CaseDispute dispute;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (dispute.status) {
      DisputeStatus.open => (Icons.error_outline, AppColors.destructiveIcon),
      DisputeStatus.takenIn => (Icons.check_circle_outline, AppColors.success),
      DisputeStatus.declined => (
        Icons.warning_amber_outlined,
        AppColors.warning,
      ),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: AppSizing.iconSm, color: color),
        const SizedBox(width: AppSizing.space8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dispute.title,
                style: AppTextStyles.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                dispute.description,
                style: AppTextStyles.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
