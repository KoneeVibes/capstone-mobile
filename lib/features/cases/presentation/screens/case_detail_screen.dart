import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/formatting/app_formatters.dart';
import '../../../../core/navigation/app_session.dart';
import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/error/async_value_x.dart';
import '../../../../core/utils/link_opener.dart';
import '../../../../shared/extensions/context_extensions.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_state_view.dart';
import '../../domain/entities/case.dart';
import '../../domain/entities/case_applicant.dart';
import '../../domain/entities/case_property.dart';
import '../providers/case_detail_provider.dart';
import '../widgets/case_assign_sheet.dart';
import '../widgets/case_detail_skeleton.dart';
import '../widgets/case_status_chip.dart';

/// One case in full, with the action that assigns or re-assigns it (staff
/// only).
class CaseDetailScreen extends ConsumerWidget {
  const CaseDetailScreen({required this.caseId, super.key});

  final String caseId;

  Future<void> _assign(BuildContext context, WidgetRef ref, Case value) async {
    // The sheet performs the write itself and reports its own failures inline,
    // so by the time it resolves true the case has already been updated.
    final assigned = await showCaseAssignSheet(context: context, value: value);
    if (assigned != true || !context.mounted) return;

    // Named from the record the write returned rather than from the person the
    // user tapped, so the confirmation states what the server actually stored.
    final name = ref.read(caseDetailProvider(caseId)).value?.assignee?.fullName;
    context.showMessage(
      name == null || name.isEmpty
          ? 'Case assigned.'
          : 'Case assigned to $name.',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(caseDetailProvider(caseId));
    final value = detail.value;
    // Assigning is staff work; clients see the case read-only.
    final isStaff = ref.watch(sessionProvider)?.isStaff ?? false;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        // The header identifies the applicant, not the screen: the person is
        // what a staff member is looking at, and the phone number is the thing
        // they most often need next.
        title: value == null
            ? const Text('Case')
            : _ApplicantHeader(applicant: value.applicant),
        actions: [
          if (value != null) CaseStatusChip(status: value.status),
          const SizedBox(width: AppSizing.screenPadding),
        ],
      ),
      body: SafeArea(
        child: detail.when2(
          loading: () => const CaseDetailSkeleton(),
          error: (failure) => AppStateView.failure(
            failure: failure,
            onRetry: failure.isRetryable
                ? () => ref.invalidate(caseDetailProvider(caseId))
                : null,
          ),
          data: (loaded) => Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSizing.screenPadding),
                  child: Column(
                    children: [
                      _CaseCard(value: loaded),
                      if (loaded.property.hasDocuments) ...[
                        const SizedBox(height: AppSizing.space16),
                        _DocumentsCard(property: loaded.property),
                      ],
                    ],
                  ),
                ),
              ),
              if (isStaff)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizing.screenPadding,
                    0,
                    AppSizing.screenPadding,
                    AppSizing.space16,
                  ),
                  child: _AssignAction(
                    value: loaded,
                    onPressed: () => _assign(context, ref, loaded),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Avatar, name and phone number, in the app bar.
class _ApplicantHeader extends StatelessWidget {
  const _ApplicantHeader({required this.applicant});

  final CaseApplicant applicant;

  @override
  Widget build(BuildContext context) {
    final phone = AppFormatters.phone(applicant.phone);

    return Row(
      children: [
        AppAvatar(initials: applicant.initials, size: AppSizing.avatarSm),
        const SizedBox(width: AppSizing.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                applicant.name,
                style: AppTextStyles.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (phone.isNotEmpty)
                Text(
                  phone,
                  style: AppTextStyles.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The assign button, and why it is unavailable when it is.
///
/// A case can be handed to someone at every point in its life except the
/// first: until the payment is validated it is not the team's to pick up. The
/// button greys out rather than disappearing — someone who saw it on the last
/// case would read its absence as a broken screen, where a disabled button
/// with a line under it answers the question it raises.
class _AssignAction extends StatelessWidget {
  const _AssignAction({required this.value, required this.onPressed});

  final Case value;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final canAssign = value.status.canBeAssigned;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppButton(
          label: value.isAssigned ? 'Re-assign case' : 'Assign to team member',
          variant: AppButtonVariant.secondary,
          onPressed: canAssign ? onPressed : null,
        ),
        if (!canAssign) ...[
          const SizedBox(height: AppSizing.space8),
          const Text(
            'This case can be assigned once its payment is validated.',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// What was asked for, and who holds it.
class _CaseCard extends StatelessWidget {
  const _CaseCard({required this.value});

  final Case value;

  @override
  Widget build(BuildContext context) {
    // `PI-URF8T7C2` — the API's own reference, and the closest thing to the
    // `SLP-101` the designs drew. Records made before the field existed do not
    // carry one, so the property still stands in as the heading there.
    final heading =
        value.trackingId ??
        (value.summary.isEmpty ? 'Case details' : value.summary);

    return _Card(
      heading: heading,
      title: 'Request',
      children: [
        for (final (index, field) in _fields(value).indexed) ...[
          if (index != 0) ...[
            const SizedBox(height: AppSizing.space16),
            const Divider(),
            const SizedBox(height: AppSizing.space16),
          ],
          _Field(label: field.$1, value: field.$2),
        ],
      ],
    );
  }

  /// The rows to draw, in order, skipping anything the case does not carry.
  static List<(String, String)> _fields(Case value) {
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
      if (address.isNotEmpty) ('Address', address),
      if (titles.isNotEmpty) ('Title type', titles),
      if (value.source != null) ('Source', AppFormatters.apiLabel(value.source)),
      if (submitted.isNotEmpty) ('Submitted', submitted),
      ('Assignment', _assignment(value)),
    ];
  }

  /// Mirrors the list row: assigned-but-unresolved is its own state, and must
  /// not read as unassigned.
  static String _assignment(Case value) {
    final name = value.assignee?.fullName;
    if (name != null && name.isNotEmpty) return name;
    return value.isAssigned ? 'Assigned' : 'Not assigned yet';
  }
}

/// The survey plans and title documents filed with the request.
class _DocumentsCard extends ConsumerWidget {
  const _DocumentsCard({required this.property});

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

    return _Card(
      heading: 'Documents',
      title: 'Filed with this request',
      children: [
        for (final (index, document) in documents.indexed) ...[
          if (index != 0) const Divider(),
          _DocumentRow(
            label: document.$1,
            onTap: () => _open(context, ref, document.$2),
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

/// One tappable document, opening outside the app.
class _DocumentRow extends StatelessWidget {
  const _DocumentRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizing.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizing.space12),
        child: Row(
          children: [
            const Icon(
              Icons.description_outlined,
              size: AppSizing.iconMd,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: AppSizing.space12),
            Expanded(child: Text(label, style: AppTextStyles.label)),
            const SizedBox(width: AppSizing.space8),
            // Signals that the tap leaves the app, so a browser opening on top
            // is expected rather than a surprise.
            const Icon(
              Icons.open_in_new,
              size: AppSizing.iconSm,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

/// The card both sections share: a heading, an edge-to-edge rule, then content.
class _Card extends StatelessWidget {
  const _Card({
    required this.heading,
    required this.title,
    required this.children,
  });

  final String heading;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSizing.space20),
            child: Text(heading, style: AppTextStyles.bodyLarge),
          ),
          // Edge to edge, unlike the rules between the rows below, so the
          // heading reads as a title over the content rather than as the first
          // field in it.
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(AppSizing.space20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleSmall),
                const SizedBox(height: AppSizing.space16),
                ...children,
              ],
            ),
          ),
        ],
      ),
    );
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
