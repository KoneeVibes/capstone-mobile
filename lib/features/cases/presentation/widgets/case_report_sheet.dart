import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/utils/error/app_failure.dart';
import '../../../../core/utils/error/async_value_x.dart';
import '../../../../core/utils/media_picker.dart';
import '../../../../core/utils/result.dart';
import '../../../../shared/widgets/app_bottom_sheet.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_upload_field.dart';
import '../providers/case_update_provider.dart';
import 'case_error_banner.dart';

/// Opens the Add Report sheet. Resolves to true once the report is submitted.
Future<bool?> showCaseReportSheet({
  required BuildContext context,
  required String caseId,
}) => showAppBottomSheet<bool>(
  context: context,
  title: 'Add Report',
  child: CaseReportSheet(caseId: caseId),
);

/// [current] plus the new files in [picked], skipping any already there.
List<PickedMedia> mergeReportFiles(
  List<PickedMedia> current,
  List<PickedMedia> picked,
) {
  final paths = current.map((file) => file.path).toSet();
  return [...current, ...picked.where((file) => paths.add(file.path))];
}

/// Collects up to [maxFiles] documents and submits them as the case's report,
/// which sends the case for review (ADR 0019).
class CaseReportSheet extends ConsumerStatefulWidget {
  const CaseReportSheet({required this.caseId, super.key});

  final String caseId;

  /// Most files one report carries: the `PUT /case/{id}` limit.
  static const int maxFiles = 5;

  @override
  ConsumerState<CaseReportSheet> createState() => _CaseReportSheetState();
}

class _CaseReportSheetState extends ConsumerState<CaseReportSheet> {
  List<PickedMedia> _files = const [];

  /// Picker problems, shown under the upload box. Inline: a snackbar would sit
  /// behind the sheet.
  String? _error;

  /// The upload's failure. Held locally so an earlier one cannot show when the
  /// sheet opens.
  AppFailure? _failure;

  Future<void> _pick() async {
    final room = CaseReportSheet.maxFiles - _files.length;
    if (room <= 0) {
      setState(
        () =>
            _error = 'You can attach up to ${CaseReportSheet.maxFiles} files.',
      );
      return;
    }

    final result = await ref
        .read(mediaPickerProvider)
        .pickDocuments(
          allowedExtensions: AppConstants.caseDocumentExtensions,
          limit: room,
        );
    if (!mounted) return;

    setState(() {
      switch (result) {
        case Err(:final failure):
          _error = failure.message;
        case Ok(:final value):
          _files = mergeReportFiles(_files, value.files);
          _error = value.dropped > 0
              ? 'Only ${CaseReportSheet.maxFiles} files per report. '
                    'The extra files were left out.'
              : null;
      }
    });
  }

  Future<void> _upload() async {
    setState(() => _failure = null);

    final submitted = await ref
        .read(caseUpdateProvider.notifier)
        .submitReport(widget.caseId, _files);
    if (!mounted) return;

    if (submitted) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() => _failure = ref.read(caseUpdateProvider).failure);
  }

  @override
  Widget build(BuildContext context) {
    final isUploading = ref.watch(caseUpdateProvider).isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppUploadField(
          label: 'Report documents',
          helper:
              'Sends the case for review, replacing any earlier report. '
              'Up to ${CaseReportSheet.maxFiles} files.',
          files: _files,
          errorText: _error,
          onPick: _pick,
          onRemove: (file) => setState(() {
            _files = [
              for (final kept in _files)
                if (kept != file) kept,
            ];
            _error = null;
          }),
        ),
        if (_failure != null) ...[
          const SizedBox(height: AppSizing.space16),
          CaseErrorBanner(failure: _failure!),
        ],
        const SizedBox(height: AppSizing.space24),
        AppButton(
          label: 'Upload',
          isLoading: isUploading,
          onPressed: _files.isEmpty ? null : _upload,
        ),
      ],
    );
  }
}
