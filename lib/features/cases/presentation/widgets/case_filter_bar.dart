import 'package:flutter/material.dart';

import '../../../../core/sizing/app_sizing.dart';
import '../../../../shared/widgets/app_chip.dart';
import '../../domain/entities/case_filter.dart';

/// The All / New / Assigned / Closed tabs above the cases list.
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
              label: _label(filter),
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

  static String _label(CaseFilter filter) => switch (filter) {
    CaseFilter.all => 'All',
    CaseFilter.newCases => 'New',
    CaseFilter.assigned => 'Assigned',
    CaseFilter.closed => 'Closed',
  };
}
