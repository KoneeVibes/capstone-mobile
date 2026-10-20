import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/formatting/app_formatters.dart';
import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/link_opener.dart';
import '../../../../shared/extensions/context_extensions.dart';
import '../../domain/entities/case.dart';
import '../../domain/entities/case_property.dart';

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
                  _DocumentGrid(property: property),
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

/// The survey plans and title documents, two to a row.
class _DocumentGrid extends ConsumerWidget {
  const _DocumentGrid({required this.property});

  final CaseProperty property;

  Future<void> _open(BuildContext context, WidgetRef ref, String url) async {
    final result = await ref.read(linkOpenerProvider).open(url);
    if (!context.mounted) return;

    // A document that will not open is worth saying out loud — the user tapped
    // it deliberately, and silence would read as the tap not registering.
    final failure = result.failureOrNull;
    if (failure != null) context.showFailure(failure);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documents = _documents(property);

    return Column(
      children: [
        for (var row = 0; row < documents.length; row += 2) ...[
          if (row > 0) const SizedBox(height: AppSizing.space8),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final i in [row, row + 1]) ...[
                  if (i != row) const SizedBox(width: AppSizing.space8),
                  Expanded(
                    child: i < documents.length
                        ? _DocumentTile(
                            label: documents[i].$1,
                            url: documents[i].$2,
                            onTap: () => _open(context, ref, documents[i].$2),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// (label, url) for every attachment, survey plans first.
  ///
  /// Numbered only when there is more than one of a kind: `Survey plan 1` on a
  /// case with a single plan would imply a second one exists.
  static List<(String, String)> _documents(CaseProperty property) => [
    for (final (index, url) in property.surveyPlans.indexed)
      (
        property.surveyPlans.length == 1
            ? 'Survey plan'
            : 'Survey plan ${index + 1}',
        url,
      ),
    for (final (index, url) in property.titleDocuments.indexed)
      (
        property.titleDocuments.length == 1
            ? 'Title document'
            : 'Title document ${index + 1}',
        url,
      ),
  ];
}

/// A file tile: its type icon, name and format. Opens outside the app.
class _DocumentTile extends StatelessWidget {
  const _DocumentTile({
    required this.label,
    required this.url,
    required this.onTap,
  });

  final String label;
  final String url;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSizing.radiusSm);
    final extension = _extension(url);
    final isPdf = extension == 'pdf';

    return Material(
      color: AppColors.surface,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Ink(
          padding: const EdgeInsets.all(AppSizing.space12),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: AppColors.border,
              width: AppSizing.borderWidth,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
                size: AppSizing.iconLg,
                color: isPdf ? AppColors.destructiveIcon : AppColors.primary,
              ),
              const SizedBox(width: AppSizing.space8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (extension.isNotEmpty)
                      Text(
                        extension.toUpperCase(),
                        style: AppTextStyles.bodySmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// `pdf` from `…/plan.pdf?x=1`, or empty when the URL names no format.
  static String _extension(String url) {
    final path = Uri.tryParse(url)?.path ?? url;
    final name = path.split('/').last;
    final dot = name.lastIndexOf('.');
    return dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
  }
}
