import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/formatting/app_formatters.dart';
import '../../../../core/navigation/app_session.dart';
import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/media_picker.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/extensions/context_extensions.dart';
import '../../../../shared/widgets/app_bottom_sheet.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_state_view.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../domain/entities/case_dispute.dart';
import '../providers/case_detail_provider.dart';
import '../providers/case_disputes_provider.dart';

/// One dispute as a timeline: what the client raised, then how staff answered.
/// Staff answer an open one here — take it in, or decline it with a note.
class DisputeDetailScreen extends ConsumerWidget {
  const DisputeDetailScreen({
    required this.caseId,
    required this.disputeId,
    super.key,
  });

  final String caseId;
  final String disputeId;

  Future<void> _decline(BuildContext context, WidgetRef ref) async {
    final note = await showAppBottomSheet<String>(
      context: context,
      title: 'Decline dispute',
      child: const _DeclineNoteForm(),
    );
    if (note == null || !context.mounted) return;
    ref.read(caseDisputesProvider(caseId).notifier).decline(disputeId, note);
    context.showMessage('Dispute cancelled.');
  }

  void _takeIn(BuildContext context, WidgetRef ref) {
    ref.read(caseDisputesProvider(caseId).notifier).takeIn(disputeId);
    context.showMessage('Dispute taken in.');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isStaff = ref.watch(sessionProvider)?.isStaff ?? false;
    final value = ref.watch(caseDetailProvider(caseId)).value;
    final dispute = ref
        .watch(caseDisputesProvider(caseId))
        .where((d) => d.id == disputeId)
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(titleSpacing: 0, title: const Text('Dispute detail')),
      body: SafeArea(
        child: dispute == null
            ? const AppStateView.empty(
                icon: Icons.search_off,
                title: 'Dispute not found',
                message: 'It may have been raised in an earlier session.',
              )
            : ListView(
                padding: const EdgeInsets.all(AppSizing.screenPadding),
                children: [
                  if (value != null) ...[
                    Text(value.headline, style: AppTextStyles.titleSmall),
                    if (value.trackingId case final reference?)
                      Text(reference, style: AppTextStyles.bodyMedium),
                    const SizedBox(height: AppSizing.space24),
                  ],
                  _TimelineEntry(
                    icon: Icons.schedule,
                    color: AppColors.textTertiary,
                    isLast: false,
                    child: _EventCard(
                      at: dispute.raisedAt,
                      title: dispute.title,
                      body: dispute.description,
                      evidence: dispute.evidence,
                    ),
                  ),
                  _response(context, ref, dispute, isStaff: isStaff),
                ],
              ),
      ),
    );
  }

  Widget _response(
    BuildContext context,
    WidgetRef ref,
    CaseDispute dispute, {
    required bool isStaff,
  }) {
    return switch (dispute.status) {
      DisputeStatus.takenIn => _TimelineEntry(
        icon: Icons.check_circle,
        color: AppColors.success,
        isLast: true,
        child: _EventCard(at: dispute.respondedAt, title: 'Dispute taken in'),
      ),
      DisputeStatus.declined => _TimelineEntry(
        icon: Icons.warning_amber_rounded,
        color: AppColors.warning,
        isLast: true,
        child: _EventCard(
          at: dispute.respondedAt,
          title: 'Dispute cancelled',
          body: dispute.declineNote,
        ),
      ),
      DisputeStatus.open when isStaff => _TimelineEntry(
        icon: Icons.warning_amber_rounded,
        color: AppColors.warning,
        isLast: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Respond to Dispute', style: AppTextStyles.titleSmall),
            const SizedBox(height: AppSizing.space12),
            Row(
              children: [
                AppButton(
                  label: 'Accept',
                  expanded: false,
                  onPressed: () => _takeIn(context, ref),
                ),
                const SizedBox(width: AppSizing.space8),
                AppButton(
                  label: 'Decline with Note',
                  variant: AppButtonVariant.destructiveOutlined,
                  expanded: false,
                  onPressed: () => _decline(context, ref),
                ),
              ],
            ),
          ],
        ),
      ),
      DisputeStatus.open => const _TimelineEntry(
        icon: Icons.hourglass_empty,
        color: AppColors.textTertiary,
        isLast: true,
        child: Padding(
          padding: EdgeInsets.only(top: AppSizing.space2),
          child: Text(
            'Waiting for the team to respond.',
            style: AppTextStyles.bodyMedium,
          ),
        ),
      ),
    };
  }
}

/// An icon on a vertical rule, with its content to the right.
class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({
    required this.icon,
    required this.color,
    required this.isLast,
    required this.child,
  });

  final IconData icon;
  final Color color;
  final bool isLast;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Icon(icon, size: AppSizing.iconLg, color: color),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: AppSizing.timelineConnectorWidth,
                    margin: const EdgeInsets.symmetric(
                      vertical: AppSizing.space4,
                    ),
                    color: AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSizing.space12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSizing.space16),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// A dated card: when, what, and any detail or files.
class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.at,
    required this.title,
    this.body,
    this.evidence = const [],
  });

  final DateTime? at;
  final String title;
  final String? body;
  final List<PickedMedia> evidence;

  @override
  Widget build(BuildContext context) {
    final body = this.body;

    return Container(
      padding: const EdgeInsets.all(AppSizing.space12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
        border: Border.all(
          color: AppColors.border,
          width: AppSizing.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppFormatters.dateTime(at), style: AppTextStyles.bodySmall),
          const SizedBox(height: AppSizing.space4),
          Text(title, style: AppTextStyles.titleSmall),
          if (body != null && body.isNotEmpty) ...[
            const SizedBox(height: AppSizing.space8),
            Text(body, style: AppTextStyles.bodyMedium),
          ],
          if (evidence.isNotEmpty) ...[
            const SizedBox(height: AppSizing.space12),
            Wrap(
              spacing: AppSizing.space8,
              runSpacing: AppSizing.space8,
              children: [
                for (final file in evidence) _EvidenceThumb(file: file),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// A picked file: the image itself, or a document icon with its name.
class _EvidenceThumb extends StatelessWidget {
  const _EvidenceThumb({required this.file});

  final PickedMedia file;

  @override
  Widget build(BuildContext context) {
    const side = AppSizing.avatarLg;
    final radius = BorderRadius.circular(AppSizing.radiusSm);

    return Tooltip(
      message: file.fileName,
      child: ClipRRect(
        borderRadius: radius,
        child: Container(
          width: side,
          height: side,
          color: AppColors.surfaceMuted,
          child: file.isImage
              ? Image.file(
                  File(file.path),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const _DocumentIcon(),
                )
              : const _DocumentIcon(),
        ),
      ),
    );
  }
}

class _DocumentIcon extends StatelessWidget {
  const _DocumentIcon();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.picture_as_pdf_outlined,
      size: AppSizing.iconLg,
      color: AppColors.destructiveIcon,
    );
  }
}

/// The note a decline must carry. Pops with the note.
class _DeclineNoteForm extends StatefulWidget {
  const _DeclineNoteForm();

  @override
  State<_DeclineNoteForm> createState() => _DeclineNoteFormState();
}

class _DeclineNoteFormState extends State<_DeclineNoteForm> {
  final _formKey = GlobalKey<FormState>();
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(_note.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            label: 'Note to the client',
            hint: 'Why is this dispute being declined?',
            controller: _note,
            textCapitalization: TextCapitalization.sentences,
            maxLines: 4,
            autofocus: true,
            validator: (value) =>
                Validators.requiredField(value, label: 'A note'),
          ),
          const SizedBox(height: AppSizing.space20),
          AppButton(
            label: 'Decline dispute',
            variant: AppButtonVariant.destructive,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
