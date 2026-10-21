import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/utils/media_picker.dart';
import '../../../../core/utils/result.dart';
import '../../../../shared/widgets/app_bottom_sheet.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_upload_field.dart';

/// Opens the Add Report sheet. Resolves to true when the report was uploaded.
Future<bool?> showCaseReportSheet({required BuildContext context}) =>
    showAppBottomSheet<bool>(
      context: context,
      title: 'Add Report',
      child: const CaseReportSheet(),
    );

/// [current] plus the new files in [picked], skipping any already there.
List<PickedMedia> mergeReportFiles(
  List<PickedMedia> current,
  List<PickedMedia> picked,
) {
  final paths = current.map((file) => file.path).toSet();
  return [...current, ...picked.where((file) => paths.add(file.path))];
}

/// Collects up to [maxFiles] documents for one report.
///
/// Mock: Upload only closes the sheet; nothing is kept (ADR 0017).
/// TODO(backend): upload through the report endpoint once it exists.
class CaseReportSheet extends ConsumerStatefulWidget {
  const CaseReportSheet({super.key});

  /// Most files one report carries.
  static const int maxFiles = 3;

  @override
  ConsumerState<CaseReportSheet> createState() => _CaseReportSheetState();
}

class _CaseReportSheetState extends ConsumerState<CaseReportSheet> {
  List<PickedMedia> _files = const [];

  /// Shown inline: a snackbar would sit behind the sheet.
  String? _error;

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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppUploadField(
          label: 'Report documents',
          helper:
              'Adds documents to the case file. '
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
        const SizedBox(height: AppSizing.space24),
        AppButton(
          label: 'Upload',
          onPressed: _files.isEmpty
              ? null
              : () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}
