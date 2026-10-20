import 'package:flutter/material.dart';

import '../../../../shared/widgets/case_summary_card.dart';
import '../../domain/entities/case.dart';
import 'case_status_chip.dart';

/// One case card in the list: reference, status, property, applicant and the
/// one action the caller worked out for it.
class CaseListTile extends StatelessWidget {
  const CaseListTile({
    required this.value,
    required this.onTap,
    super.key,
    this.actionLabel,
    this.onAction,
  });

  final Case value;
  final VoidCallback onTap;

  /// No button when null.
  final String? actionLabel;

  /// Null greys the button out.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return CaseSummaryCard(
      reference: value.trackingId,
      title: value.headline,
      subtitle: value.applicant.name,
      status: CaseStatusChip(status: value.status),
      actionLabel: actionLabel,
      onAction: onAction,
      onTap: onTap,
    );
  }
}
