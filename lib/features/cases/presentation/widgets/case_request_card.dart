import 'package:flutter/material.dart';

import '../../../../core/formatting/app_formatters.dart';
import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/case.dart';
import 'case_document_tile.dart';

/// The case card on the detail screen: `Case PI-…` with an optional [menu],
/// what was asked for, and the documents filed with it.
class CaseRequestCard extends StatelessWidget {
  const CaseRequestCard({
    required this.value,
    required this.showAssignment,
    super.key,
    this.menu,
  });

  final Case value;

  /// Who holds the case — staff business, so clients do not see the row.
  final bool showAssignment;

  /// The ⋮ (staff) beside the heading.
  final Widget? menu;

  @override
  Widget build(BuildContext context) {
    final reference = value.trackingId;
    final fields = _fields(value, showAssignment: showAssignment);
    final property = value.property;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSizing.space20,
              AppSizing.space12,
              menu == null ? AppSizing.space20 : AppSizing.space4,
              AppSizing.space12,
            ),
            child: SizedBox(
              height: AppSizing.iconButtonSize,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      reference == null ? 'Case details' : 'Case $reference',
                      style: AppTextStyles.bodyLarge,
                    ),
                  ),
                  ?menu,
                ],
              ),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(AppSizing.space20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Request', style: AppTextStyles.titleSmall),
                const SizedBox(height: AppSizing.space16),
                for (final (index, field) in fields.indexed) ...[
                  if (index != 0) ...[
                    const SizedBox(height: AppSizing.space12),
                    const Divider(),
                    const SizedBox(height: AppSizing.space12),
                  ],
                  _Field(label: field.$1, value: field.$2),
                ],
                if (property.hasDocuments) ...[
                  const SizedBox(height: AppSizing.space24),
                  const Text(
                    'Property Documents',
                    style: AppTextStyles.titleSmall,
                  ),
                  const SizedBox(height: AppSizing.space12),
                  CaseDocumentGrid(
                    documents: [
                      ...CaseDocumentGrid.numbered(
                        'Survey plan',
                        property.surveyPlans,
                      ),
                      ...CaseDocumentGrid.numbered(
                        'Title document',
                        property.titleDocuments,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The rows to draw, in order, skipping anything the case does not carry.
  static List<(String, String)> _fields(
    Case value, {
    required bool showAssignment,
  }) {
    final property = value.property;
    final purpose = value.purposeLabel;
    final titles = property.titleTypes
        .map(AppFormatters.apiLabel)
        .where((title) => title.isNotEmpty)
        .join(', ');
    final address = property.fullAddress;
    final submitted = AppFormatters.date(value.createdAt);

    return [
      if (property.typeLabel.isNotEmpty) ('Property type', property.typeLabel),
      if (purpose.isNotEmpty) ('Purpose', purpose),
      if (address.isNotEmpty) ('Location', address),
      if (titles.isNotEmpty) ('Title type', titles),
      if (submitted.isNotEmpty) ('Submitted', submitted),
      if (showAssignment) ('Assignment', _assignment(value)),
    ];
  }

  /// Assigned-but-unresolved is its own state, and must not read as
  /// unassigned.
  static String _assignment(Case value) {
    final name = value.assignee?.fullName;
    if (name != null && name.isNotEmpty) return name;
    return value.isAssigned ? 'Assigned' : 'Not assigned yet';
  }
}

/// One label-over-value pair.
class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodyMedium),
        const SizedBox(height: AppSizing.space4),
        Text(value, style: AppTextStyles.label),
      ],
    );
  }
}
