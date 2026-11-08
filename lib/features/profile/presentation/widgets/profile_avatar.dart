import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_avatar.dart';

/// The large round photo, with a pencil badge when [onEdit] is given.
///
/// A [pickedPath] (chosen, not yet saved) wins over the stored [imageUrl].
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    required this.initials,
    super.key,
    this.imageUrl,
    this.pickedPath,
    this.onEdit,
    this.busy = false,
  });

  final String initials;
  final String? imageUrl;
  final String? pickedPath;
  final VoidCallback? onEdit;

  /// Shows a spinner over the photo while it uploads.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final picked = pickedPath;
    final photo = picked != null
        ? ClipOval(
            child: Image.file(
              File(picked),
              width: AppSizing.avatarXl,
              height: AppSizing.avatarXl,
              fit: BoxFit.cover,
            ),
          )
        : AppAvatar(
            initials: initials,
            imageUrl: imageUrl,
            size: AppSizing.avatarXl,
            circular: true,
          );

    return SizedBox.square(
      dimension: AppSizing.avatarXl,
      child: Stack(
        children: [
          photo,
          if (busy)
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.overlay,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textOnPrimary,
                  ),
                ),
              ),
            ),
          if (onEdit != null)
            Positioned(
              right: 0,
              bottom: 0,
              child: Semantics(
                button: true,
                label: 'Change photo',
                child: InkWell(
                  onTap: busy ? null : onEdit,
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: AppSizing.avatarBadge,
                    height: AppSizing.avatarBadge,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      size: AppSizing.iconXs,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
