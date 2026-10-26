import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/formatting/app_formatters.dart';
import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/document_preview.dart';
import '../../../../core/utils/error/app_failure.dart';
import '../../../../core/utils/error/async_value_x.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_confirm_dialog.dart';
import '../../domain/entities/case.dart';
import '../providers/case_detail_provider.dart';
import '../providers/case_update_provider.dart';
import 'case_document_pages.dart';
import 'case_document_tile.dart';
import 'case_document_view.dart';
import 'case_error_banner.dart';

/// Opens the report for review. Resolves to true once it is accepted.
Future<bool?> showCaseReportView({
  required BuildContext context,
  required String caseId,
}) => showCaseFileDialog<bool>(
  context: context,
  child: CaseReportView(caseId: caseId),
);

/// Every report file, drawn in one scroll, with Exit and Accept report.
///
/// Accepting closes the case. There is no Reject: the API has none, so Exit
/// only closes the view and the assignee is told outside the app (ADR 0019).
/// Reads the case afresh, so a view opened from a list card shows the report
/// as it stands.
class CaseReportView extends ConsumerStatefulWidget {
  const CaseReportView({required this.caseId, super.key});

  final String caseId;

  @override
  ConsumerState<CaseReportView> createState() => _CaseReportViewState();
}

class _CaseReportViewState extends ConsumerState<CaseReportView> {
  /// Held locally so an earlier failure cannot show when the view opens.
  AppFailure? _failure;

  Future<void> _accept() async {
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Accept Case',
      message: 'Are you sure you want to accept this case?',
      confirmLabel: 'Confirm',
      cancelLabel: 'Cancel',
      icon: null,
      isDestructive: false,
      stackActions: true,
    );
    if (!confirmed || !mounted) return;

    setState(() => _failure = null);
    final closed = await ref
        .read(caseUpdateProvider.notifier)
        .close(widget.caseId);
    if (!mounted) return;

    if (closed) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() => _failure = ref.read(caseUpdateProvider).failure);
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(caseDetailProvider(widget.caseId));
    final isSaving = ref.watch(caseUpdateProvider).isLoading;
    final updated = AppFormatters.date(detail.value?.updatedAt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizing.space20,
            AppSizing.space20,
            AppSizing.space20,
            AppSizing.space16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Report', style: AppTextStyles.bodySmall),
              const SizedBox(height: AppSizing.space4),
              const Text('Property report', style: AppTextStyles.titleLarge),
              if (updated.isNotEmpty) ...[
                const SizedBox(height: AppSizing.space4),
                Text(
                  'Last updated on $updated',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ],
          ),
        ),
        const Divider(height: AppSizing.borderWidth),
        Expanded(
          child: detail.when2(
            loading: () => ListView(
              padding: const EdgeInsets.all(AppSizing.space20),
              children: const [CaseDocumentPageSkeleton()],
            ),
            error: (failure) => Padding(
              padding: const EdgeInsets.all(AppSizing.space20),
              child: CaseErrorBanner(
                failure: failure,
                onRetry: () =>
                    ref.invalidate(caseDetailProvider(widget.caseId)),
              ),
            ),
            data: (value) => _Files(value: value),
          ),
        ),
        if (_failure != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizing.space16,
              AppSizing.space12,
              AppSizing.space16,
              0,
            ),
            child: CaseErrorBanner(failure: _failure!),
          ),
        Padding(
          padding: const EdgeInsets.all(AppSizing.space16),
          child: Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Exit',
                  variant: AppButtonVariant.secondary,
                  onPressed: isSaving
                      ? null
                      : () => Navigator.of(context).pop(false),
                ),
              ),
              const SizedBox(width: AppSizing.space12),
              Expanded(
                child: AppButton(
                  label: 'Accept report',
                  isLoading: isSaving,
                  onPressed: detail.hasValue ? _accept : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Each report file in turn, labelled when there is more than one.
class _Files extends StatelessWidget {
  const _Files({required this.value});

  final Case value;

  @override
  Widget build(BuildContext context) {
    final reports = value.reports;
    if (reports.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppSizing.space20),
        child: Text(
          'No report files came with this case.',
          style: AppTextStyles.bodyMedium,
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSizing.space20),
      children: [
        for (final (index, url) in reports.indexed) ...[
          if (index != 0) const SizedBox(height: AppSizing.space24),
          if (reports.length > 1) ...[
            Text(
              'Report ${index + 1} of ${reports.length}',
              style: AppTextStyles.label,
            ),
            const SizedBox(height: AppSizing.space8),
          ],
          // A type the app cannot draw is still one tap from being read.
          if (DocumentPreview.kindOf(url) == null)
            CaseDocumentTile(label: 'Report file', url: url)
          else
            CaseDocumentPages(url: url),
        ],
      ],
    );
  }
}
