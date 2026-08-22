import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_chip.dart';
import '../../domain/entities/case_status.dart';

/// The status pill, on both the list rows and the detail header.
///
/// Label and colour are mapped here because this is the only place a status is
/// drawn: keeping the copy at the point of render is why there is no shared
/// strings file. An unrecognised status renders nothing rather than the word
/// "unknown", which would tell the user less than an absent pill.
class CaseStatusChip extends StatelessWidget {
  const CaseStatusChip({required this.status, super.key});

  final CaseStatus status;

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
  ///
  /// `pending-information` is the one status drawn in the destructive palette.
  /// It is not an error — it is a legitimate state — but it is the only one
  /// where the case is stalled until somebody chases the applicant, and it
  /// should catch the eye on a list of thirty rows.
  ///
  /// Labels are shortened where the API's value is not: the pill sits beside
  /// the applicant's name on a narrow phone, and `Pending information` in full
  /// would squeeze the name it is meant to annotate.
  static (String, Color, Color) _style(CaseStatus status) => switch (status) {
    CaseStatus.submitted => ('New', AppColors.infoSoft, AppColors.info),
    CaseStatus.assigned => (
      'Assigned',
      AppColors.warningSoft,
      AppColors.warning,
    ),
    CaseStatus.accepted => (
      'Accepted',
      AppColors.successSoft,
      AppColors.success,
    ),
    CaseStatus.pendingInformation => (
      'Pending info',
      AppColors.destructiveSoft,
      AppColors.destructive,
    ),
    CaseStatus.underReview => (
      'Under review',
      AppColors.primarySoft,
      AppColors.primary,
    ),
    CaseStatus.closed => (
      'Closed',
      AppColors.surfaceMuted,
      AppColors.textSecondary,
    ),
    // Unreachable: guarded above. Present so the switch stays exhaustive and a
    // new status has to be given colours deliberately.
    CaseStatus.unknown => ('', AppColors.surfaceMuted, AppColors.textTertiary),
  };
}
