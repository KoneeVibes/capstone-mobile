import 'package:flutter/material.dart';

import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/document_preview.dart';
import '../../../../shared/extensions/context_extensions.dart';
import '../../../../shared/widgets/app_button.dart';
import 'case_document_pages.dart';

/// The frame both file views open in: the document view and the report
/// review.
Future<T?> showCaseFileDialog<T>({
  required BuildContext context,
  required Widget child,
}) {
  context.hideKeyboard();
  return showDialog<T>(
    context: context,
    barrierColor: AppColors.overlay,
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSizing.screenPadding,
        vertical: AppSizing.space24,
      ),
      backgroundColor: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
      ),
      child: child,
    ),
  );
}

/// Opens one case file — a property document or a report file — to read in
/// the app.
Future<void> showCaseDocumentView({
  required BuildContext context,
  required String label,
  required String url,
}) => showCaseFileDialog<void>(
  context: context,
  child: CaseDocumentView(label: label, url: url),
);

/// One file drawn page by page, read-only, with Exit.
///
/// Exit rather than Close, as in the report review: on a case screen "Close"
/// reads as closing the case (ADR 0022).
class CaseDocumentView extends StatelessWidget {
  const CaseDocumentView({required this.label, required this.url, super.key});

  /// The tile's name, such as `Survey plan 1`.
  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    final format = DocumentPreview.extensionOf(url).toUpperCase();

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
              if (format.isNotEmpty) ...[
                Text(format, style: AppTextStyles.bodySmall),
                const SizedBox(height: AppSizing.space4),
              ],
              Text(label, style: AppTextStyles.titleLarge),
            ],
          ),
        ),
        const Divider(height: AppSizing.borderWidth),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSizing.space20),
            children: [CaseDocumentPages(url: url)],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSizing.space16),
          child: AppButton(
            label: 'Exit',
            variant: AppButtonVariant.secondary,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
  }
}
