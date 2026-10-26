import 'package:flutter/material.dart';

import '../../core/sizing/app_sizing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/media_picker.dart';
import '../extensions/context_extensions.dart';

/// An upload box that collects several files, listing each with a remove
/// button. The caller supplies the wording.
class AppUploadField extends StatelessWidget {
  /// Creates the field. All wording comes from the caller.
  const AppUploadField({
    required this.label,
    required this.helper,
    required this.files,
    required this.onPick,
    required this.onRemove,
    super.key,
    this.errorText,
    this.clearAllLabel,
    this.onClearAll,
  });

  /// The heading above the box.
  final String label;

  /// What counts, e.g. "C of O, deed, receipts".
  final String helper;

  /// The files chosen so far, listed under the box.
  final List<PickedMedia> files;

  /// Opens the picker.
  final VoidCallback onPick;

  /// Drops one file from [files].
  final ValueChanged<PickedMedia> onRemove;

  /// Replaces [helper] and outlines the box in red.
  final String? errorText;

  /// With [onClearAll], a link over the file list that empties it.
  final String? clearAllLabel;

  /// Empties [files].
  final VoidCallback? onClearAll;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSizing.radiusMd);
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: AppSizing.space8),
        Material(
          color: AppColors.surface,
          borderRadius: radius,
          child: InkWell(
            onTap: () {
              context.hideKeyboard();
              onPick();
            },
            borderRadius: radius,
            child: Ink(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizing.space16),
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(
                  color: hasError ? AppColors.destructive : AppColors.border,
                  width: AppSizing.borderWidth,
                ),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.upload_file_outlined,
                    size: AppSizing.iconLg,
                    color: AppColors.primary,
                  ),
                  SizedBox(height: AppSizing.space8),
                  Text('Tap to upload', style: AppTextStyles.titleSmall),
                  SizedBox(height: AppSizing.space2),
                  Text(
                    'PDF, JPG, JPEG or PNG, less than 10MB',
                    style: AppTextStyles.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSizing.space6),
        Text(
          errorText ?? helper,
          style: AppTextStyles.bodySmall.copyWith(
            color: hasError ? AppColors.destructive : null,
          ),
        ),
        if (clearAllLabel case final clearAll?
            when onClearAll != null && files.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onClearAll,
              child: Text(clearAll, style: AppTextStyles.link),
            ),
          ),
        for (final file in files) ...[
          const SizedBox(height: AppSizing.space8),
          _FileRow(file: file, onRemove: () => onRemove(file)),
        ],
      ],
    );
  }
}

class _FileRow extends StatelessWidget {
  const _FileRow({required this.file, required this.onRemove});

  final PickedMedia file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: AppSizing.space12),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSizing.radiusSm),
      ),
      child: Row(
        children: [
          Icon(
            file.isImage ? Icons.image_outlined : Icons.picture_as_pdf_outlined,
            size: AppSizing.iconSm,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppSizing.space8),
          Expanded(
            child: Text(
              file.fileName,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(file.displaySize, style: AppTextStyles.bodySmall),
          IconButton(
            tooltip: 'Remove ${file.fileName}',
            onPressed: onRemove,
            icon: const Icon(
              Icons.close,
              size: AppSizing.iconSm,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
