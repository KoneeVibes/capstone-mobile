import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/formatting/app_formatters.dart';
import '../../../../core/navigation/app_session.dart';
import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/error/async_value_x.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/extensions/context_extensions.dart';
import '../../../../shared/widgets/app_bottom_sheet.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_confirm_dialog.dart';
import '../../../../shared/widgets/app_shimmer.dart';
import '../../../../shared/widgets/app_state_view.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../domain/entities/case.dart';
import '../../domain/entities/case_dispute.dart';
import '../../domain/entities/case_status.dart';
import '../case_action_runner.dart';
import '../providers/case_detail_provider.dart';
import '../providers/case_disputes_provider.dart';
import '../providers/case_update_provider.dart';
import '../providers/dispute_update_provider.dart';
import '../widgets/case_document_tile.dart';

/// One dispute as a timeline: what the client raised, then how staff answered.
/// The assignee or a manager answers an open one here: take it in, or decline
/// it with a note (ADR 0025).
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

    final declined = await ref
        .read(disputeUpdateProvider.notifier)
        .decline(caseId: caseId, disputeId: disputeId, note: note);
    if (!context.mounted) return;
    if (declined) {
      context.showMessage('Dispute cancelled.');
    } else if (ref.read(disputeUpdateProvider).failure case final failure?) {
      context.showFailure(failure);
    }
  }

  Future<void> _takeIn(BuildContext context, WidgetRef ref) async {
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Accept Dispute',
      message:
          'The case moves to disputed and its report has to be submitted '
          'again. Accept this dispute?',
      confirmLabel: 'Confirm',
      cancelLabel: 'Cancel',
      icon: null,
      isDestructive: false,
      stackActions: true,
    );
    if (!confirmed || !context.mounted) return;

    final takenIn = await ref
        .read(caseUpdateProvider.notifier)
        .takeInDispute(caseId);
    if (!context.mounted) return;
    if (takenIn) {
      context.showMessage('Dispute taken in.');
    } else if (ref.read(caseUpdateProvider).failure case final failure?) {
      context.showFailure(failure);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isStaff = ref.watch(sessionProvider)?.isStaff ?? false;
    final value = ref.watch(caseDetailProvider(caseId)).value;
    final disputes = ref.watch(caseDisputesProvider(caseId));

    return Scaffold(
      appBar: AppBar(titleSpacing: 0, title: const Text('Dispute detail')),
      body: SafeArea(
        child: disputes.when2(
          loading: () => const _DisputeSkeleton(),
          error: (failure) => AppStateView.failure(
            failure: failure,
            onRetry: failure.isRetryable
                ? () => ref.invalidate(caseDisputesProvider(caseId))
                : null,
          ),
          data: (loaded) {
            final dispute = loaded.where((d) => d.id == disputeId).firstOrNull;
            if (dispute == null) {
              return const AppStateView.empty(
                icon: Icons.search_off,
                title: 'Dispute not found',
                message: 'It is no longer on this case.',
              );
            }
            return ListView(
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
                    at: dispute.createdAt,
                    title: dispute.title,
                    body: dispute.description,
                    attachments: dispute.attachments,
                  ),
                ),
                _response(context, ref, dispute, value, isStaff: isStaff),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _response(
    BuildContext context,
    WidgetRef ref,
    CaseDispute dispute,
    Case? value, {
    required bool isStaff,
  }) {
    final viewer = caseViewerOf(ref);
    final canAccept =
        isStaff && value != null && viewer.canAcceptDispute(value, dispute);
    final canDecline =
        isStaff && value != null && viewer.canDeclineDispute(value, dispute);
    // Once the case says disputed it has been taken in, even if the dispute
    // record has not caught up.
    final caseTookItIn = value?.status == CaseStatus.disputed;

    return switch (dispute.status) {
      DisputeStatus.accepted => _TimelineEntry(
        icon: Icons.check_circle,
        color: AppColors.success,
        isLast: true,
        child: _EventCard(at: dispute.respondedAt, title: 'Dispute taken in'),
      ),
      DisputeStatus.rejected => _TimelineEntry(
        icon: Icons.warning_amber_rounded,
        color: AppColors.warning,
        isLast: true,
        child: _EventCard(
          at: dispute.respondedAt,
          title: 'Dispute cancelled',
          body: dispute.rejectionNote,
        ),
      ),
      DisputeStatus.unknown => _TimelineEntry(
        icon: Icons.info_outline,
        color: AppColors.textTertiary,
        isLast: true,
        child: _EventCard(at: dispute.respondedAt, title: 'Dispute answered'),
      ),
      DisputeStatus.open when caseTookItIn => const _TimelineEntry(
        icon: Icons.check_circle,
        color: AppColors.success,
        isLast: true,
        child: _EventCard(at: null, title: 'Dispute taken in'),
      ),
      DisputeStatus.open when canAccept || canDecline => _TimelineEntry(
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
                if (canAccept) ...[
                  AppButton(
                    label: 'Accept',
                    expanded: false,
                    isLoading: ref.watch(caseUpdateProvider).isLoading,
                    onPressed: () => _takeIn(context, ref),
                  ),
                  const SizedBox(width: AppSizing.space8),
                ],
                AppButton(
                  label: 'Decline with Note',
                  variant: AppButtonVariant.destructiveOutlined,
                  expanded: false,
                  isLoading: ref.watch(disputeUpdateProvider).isLoading,
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

/// Placeholder while the case's disputes load: the heading and the raised
/// card.
class _DisputeSkeleton extends StatelessWidget {
  const _DisputeSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSizing.screenPadding),
      child: AppShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppShimmerBox(width: 180, height: AppSizing.space16),
            SizedBox(height: AppSizing.space6),
            AppShimmerBox(width: 120),
            SizedBox(height: AppSizing.space24),
            AppShimmerBox(height: 120, radius: AppSizing.radiusMd),
          ],
        ),
      ),
    );
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
    this.attachments = const [],
  });

  final DateTime? at;
  final String title;
  final String? body;

  /// File URLs, opened in the app like a case's documents (ADR 0022).
  final List<String> attachments;

  @override
  Widget build(BuildContext context) {
    final body = this.body;
    final at = this.at;

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
          if (at != null) ...[
            Text(AppFormatters.dateTime(at), style: AppTextStyles.bodySmall),
            const SizedBox(height: AppSizing.space4),
          ],
          Text(title, style: AppTextStyles.titleSmall),
          if (body != null && body.isNotEmpty) ...[
            const SizedBox(height: AppSizing.space8),
            Text(body, style: AppTextStyles.bodyMedium),
          ],
          if (attachments.isNotEmpty) ...[
            const SizedBox(height: AppSizing.space12),
            CaseDocumentGrid(
              documents: CaseDocumentGrid.numbered('Evidence', attachments),
            ),
          ],
        ],
      ),
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
