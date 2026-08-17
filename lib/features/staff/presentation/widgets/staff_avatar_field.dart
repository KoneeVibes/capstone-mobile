import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_avatar.dart';

/// Optional profile photo control for the staff form.
///
/// Three states: nothing chosen, a newly picked file, or an existing photo on a
/// record being edited.
///
/// The clear button only discards a *pending* selection. The API retains an
/// existing avatar unless a new image is uploaded and offers no way to delete
/// one, so this never pretends a stored photo can be removed.
class StaffAvatarField extends StatelessWidget {
  const StaffAvatarField({
    required this.pickedPath,
    required this.onPick,
    required this.onClear,
    super.key,
    this.existingUrl,
    this.initials = '',
    this.enabled = true,
  });

  /// Path of a photo chosen in this session, or null if none.
  final String? pickedPath;

  /// Photo already stored against the record, when editing.
  final String? existingUrl;

  final String initials;
  final VoidCallback onPick;
  final VoidCallback onClear;
  final bool enabled;

  bool get _hasPicked => pickedPath != null && pickedPath!.isNotEmpty;

  bool get _hasExisting => existingUrl != null && existingUrl!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Profile photo (optional)', style: AppTextStyles.label),
        const SizedBox(height: AppSizing.space8),
        Row(
          children: [
            _Preview(
              pickedPath: pickedPath,
              existingUrl: existingUrl,
              initials: initials,
              onTap: enabled ? onPick : null,
            ),
            const SizedBox(width: AppSizing.space16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: enabled ? onPick : null,
                    child: Text(
                      _hasPicked || _hasExisting
                          ? 'Change photo'
                          : 'Add photo',
                      style: AppTextStyles.label.copyWith(
                        color: enabled
                            ? AppColors.primaryBright
                            : AppColors.disabledText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizing.space2),
                  Text(
                    _hasPicked
                        ? 'Ready to upload'
                        : 'Optional · JPG or PNG',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            if (_hasPicked)
              IconButton(
                onPressed: enabled ? onClear : null,
                icon: const Icon(Icons.close, size: AppSizing.iconSm),
                color: AppColors.textSecondary,
                tooltip: 'Discard selected photo',
              ),
          ],
        ),
      ],
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({
    required this.pickedPath,
    required this.existingUrl,
    required this.initials,
    required this.onTap,
  });

  final String? pickedPath;
  final String? existingUrl;
  final String initials;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSizing.radiusMd);
    final picked = pickedPath;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: AppSizing.avatarLg,
        width: AppSizing.avatarLg,
        child: picked != null && picked.isNotEmpty
            ? ClipRRect(
                borderRadius: radius,
                child: Image.file(
                  File(picked),
                  fit: BoxFit.cover,
                  // A file that vanished between picking and rendering should
                  // not break the form.
                  errorBuilder: (_, _, _) => const _EmptyTile(),
                ),
              )
            : existingUrl != null && existingUrl!.isNotEmpty
            ? AppAvatar(
                initials: initials,
                imageUrl: existingUrl,
                size: AppSizing.avatarLg,
              )
            : const _EmptyTile(),
      ),
    );
  }
}

/// The "no photo yet" tile.
class _EmptyTile extends StatelessWidget {
  const _EmptyTile();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
        border: Border.all(
          color: AppColors.border,
          width: AppSizing.borderWidth,
        ),
      ),
      child: const Icon(
        Icons.add_a_photo_outlined,
        size: AppSizing.iconMd,
        color: AppColors.textTertiary,
      ),
    );
  }
}
