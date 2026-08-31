import 'package:flutter/material.dart';

import '../../../../core/sizing/app_sizing.dart';
import '../../../../shared/widgets/app_chip.dart';
import '../../domain/entities/case_filter.dart';

/// The tab bar above the cases list: All, then one chip per status.
///
/// Scrolls horizontally — nine chips do not fit on a phone, and the row is
/// deliberately not wrapped or squeezed to make them: a status is either worth
/// its own tab at full width or it is not.
///
/// Stays mounted and inert while the list loads, so arriving cases do not push
/// the whole screen down.
class CaseFilterBar extends StatelessWidget {
  const CaseFilterBar({
    required this.selected,
    required this.onSelected,
    super.key,
    this.enabled = true,
  });

  final CaseFilter selected;
  final ValueChanged<CaseFilter> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSizing.screenPadding),
      child: Row(
        children: [
          for (final filter in CaseFilter.values) ...[
            AppChoiceChip(
              label: label(filter),
              isSelected: filter == selected,
              style: AppChoiceChipStyle.neutral,
              enabled: enabled,
              onSelected: () => onSelected(filter),
            ),
            if (filter != CaseFilter.values.last)
              const SizedBox(width: AppSizing.space8),
          ],
        ],
      ),
    );
  }

  /// Each label matches the status pill it filters for, so a row and the tab
  /// that produced it say the same word. Shared with the list's empty states,
  /// which name the tab they are empty for.
  static String label(CaseFilter filter) => switch (filter) {
    CaseFilter.all => 'All',
    CaseFilter.submitted => 'Submitted',
    CaseFilter.paymentValidated => 'Validated',
    CaseFilter.assigned => 'Assigned',
    CaseFilter.accepted => 'Accepted',
    CaseFilter.pendingInformation => 'Pending info',
    CaseFilter.underReview => 'Under review',
    CaseFilter.closed => 'Closed',
    CaseFilter.suspended => 'Suspended',
  };
}
