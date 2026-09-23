import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_chip.dart';
import '../../domain/entities/tracking_status.dart';

/// Status pill. Labels and colours match the cases feature's pill on purpose.
class TrackingStatusChip extends StatelessWidget {
  const TrackingStatusChip({required this.status, super.key});

  final TrackingStatus status;

  static String labelOf(TrackingStatus status) => _style(status).$1;

  @override
  Widget build(BuildContext context) {
    if (!status.isKnown) return const SizedBox.shrink();

    final (label, background, foreground) = _style(status);
    return AppChip(
      label: label,
      backgroundColor: background,
      foregroundColor: foreground,
    );
  }

  /// (label, background, foreground)
  static (String, Color, Color) _style(TrackingStatus status) =>
      switch (status) {
        TrackingStatus.submitted => (
          'Submitted',
          AppColors.infoSoft,
          AppColors.info,
        ),
        TrackingStatus.paymentValidated => (
          'Validated',
          AppColors.accentSoft,
          AppColors.accent,
        ),
        TrackingStatus.assigned => (
          'Assigned',
          AppColors.warningSoft,
          AppColors.warning,
        ),
        TrackingStatus.accepted => (
          'Accepted',
          AppColors.successSoft,
          AppColors.success,
        ),
        TrackingStatus.pendingInformation => (
          'Pending info',
          AppColors.destructiveSoft,
          AppColors.destructive,
        ),
        TrackingStatus.underReview => (
          'Under review',
          AppColors.primarySoft,
          AppColors.primary,
        ),
        TrackingStatus.closed => (
          'Closed',
          AppColors.surfaceMuted,
          AppColors.textSecondary,
        ),
        TrackingStatus.suspended => (
          'Suspended',
          AppColors.surfaceMuted,
          AppColors.destructive,
        ),
        TrackingStatus.unknown => (
          '',
          AppColors.surfaceMuted,
          AppColors.textTertiary,
        ),
      };
}
