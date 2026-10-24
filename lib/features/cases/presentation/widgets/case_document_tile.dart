import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/link_opener.dart';
import '../../../../shared/extensions/context_extensions.dart';

/// Files as tiles, two to a row: the request's documents, or a report.
class CaseDocumentGrid extends StatelessWidget {
  const CaseDocumentGrid({required this.documents, super.key});

  /// (label, url), in display order.
  final List<(String, String)> documents;

  /// `Report` for one file, `Report 1`, `Report 2`… for several: numbering a
  /// lone file would imply a second one exists.
  static List<(String, String)> numbered(String label, List<String> urls) => [
    for (final (index, url) in urls.indexed)
      (urls.length == 1 ? label : '$label ${index + 1}', url),
  ];

  @override
  Widget build(BuildContext context) {
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
                        ? CaseDocumentTile(
                            label: documents[i].$1,
                            url: documents[i].$2,
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
}

/// A file tile: its type icon, name and format. Opens outside the app.
class CaseDocumentTile extends ConsumerWidget {
  const CaseDocumentTile({required this.label, required this.url, super.key});

  final String label;
  final String url;

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(linkOpenerProvider).open(url);
    if (!context.mounted) return;

    // A document that will not open is worth saying out loud — the user tapped
    // it deliberately, and silence would read as the tap not registering.
    final failure = result.failureOrNull;
    if (failure != null) context.showFailure(failure);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final radius = BorderRadius.circular(AppSizing.radiusSm);
    final extension = _extension(url);
    final isPdf = extension == 'pdf';

    return Material(
      color: AppColors.surface,
      borderRadius: radius,
      child: InkWell(
        onTap: () => _open(context, ref),
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
