import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_chip.dart';
import '../../domain/entities/queue_status.dart';

/// The status pill on a queue card.
///
/// Labels and colours are kept here, at the one place a queue status is drawn.
/// Colours follow the app's established status palette — the same soft/strong
/// pairs the cases and tracking pills use — not the Figma mock. `disputed` has
/// no server value yet; it borrows the muted terminal treatment (like `closed`
/// and `suspended`) with a warning tint, provisionally.
class QueueStatusChip extends StatelessWidget {
  const QueueStatusChip({required this.status, super.key});

  final QueueStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, background, foreground) = _style(status);
    return AppChip(
      label: label,
      backgroundColor: background,
      foregroundColor: foreground,
    );
  }

  /// (label, background, foreground)
  static (String, Color, Color) _style(QueueStatus status) => switch (status) {
    QueueStatus.paymentValidated => (
      'Payment Verified',
      AppColors.accentSoft,
      AppColors.accent,
    ),
    QueueStatus.submitted => ('Submitted', AppColors.infoSoft, AppColors.info),
    QueueStatus.assigned => (
      'Assigned',
      AppColors.warningSoft,
      AppColors.warning,
    ),
    QueueStatus.accepted => (
      'Accepted',
      AppColors.successSoft,
      AppColors.success,
    ),
    QueueStatus.pendingInformation => (
      'Pending information',
      AppColors.destructiveSoft,
      AppColors.destructive,
    ),
    QueueStatus.underReview => (
      'Under Review',
      AppColors.primarySoft,
      AppColors.primary,
    ),
    QueueStatus.closed => (
      'Closed',
      AppColors.surfaceMuted,
      AppColors.textSecondary,
    ),
    QueueStatus.suspended => (
      'Suspended',
      AppColors.surfaceMuted,
      AppColors.destructive,
    ),
    QueueStatus.disputed => (
      'Disputed',
      AppColors.surfaceMuted,
      AppColors.warning,
    ),
  };
}
