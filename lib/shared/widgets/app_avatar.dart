import 'package:flutter/material.dart';

import '../../core/sizing/app_sizing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Rounded square avatar showing initials, or a remote image when one exists.
///
/// A failed or slow image falls back to the initials rather than a broken-image
/// glyph, so a list never shows a gap.
class AppAvatar extends StatelessWidget {
  /// Creates an avatar. Build [initials] with `AppFormatters.initials`.
  const AppAvatar({
    required this.initials,
    super.key,
    this.imageUrl,
    this.size = AppSizing.avatarMd,
    this.backgroundColor = AppColors.primary,
    this.foregroundColor = AppColors.textOnPrimary,
  });

  /// One or two letters, shown when there is no image or it fails to load.
  final String initials;

  /// The photo, when one exists. Null or empty shows [initials].
  final String? imageUrl;

  /// Edge length; use an `AppSizing.avatar*` value.
  final double size;

  /// Fill behind the initials.
  final Color backgroundColor;

  /// Colour of the initials.
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSizing.radiusMd);

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        height: size,
        width: size,
        child: ColoredBox(
          color: backgroundColor,
          child: imageUrl == null || imageUrl!.isEmpty
              ? _initials()
              : Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _initials(),
                  loadingBuilder: (context, child, progress) =>
                      progress == null ? child : _initials(),
                ),
        ),
      ),
    );
  }

  Widget _initials() => Center(
    child: Text(
      initials,
      style: AppTextStyles.avatar.copyWith(
        color: foregroundColor,
        fontSize: size * 0.34,
      ),
    ),
  );
}
