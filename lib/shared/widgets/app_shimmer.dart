import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/sizing/app_sizing.dart';
import '../../core/theme/app_colors.dart';

/// Wraps a skeleton layout in the app's shimmer animation.
///
/// The `shimmer` package is imported here and nowhere else, so the dependency
/// sits behind a single file and the animation stays identical everywhere.
///
/// Use skeletons for content whose shape is known ahead of time — a list, a
/// card, a detail header. Indeterminate work with no shape to preview (a button
/// submitting, a pull-to-refresh) keeps a spinner.
class AppShimmer extends StatelessWidget {
  /// Animates [child]. Put it inside a card, around [AppShimmerBox]es only —
  /// wrapping the card itself greys out its background too.
  const AppShimmer({required this.child, super.key});

  /// The skeleton, laid out like the real content.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Base is the darker of the two: the skeleton usually sits on a white card,
    // where a lighter base would be invisible.
    return Shimmer.fromColors(
      baseColor: AppColors.border,
      highlightColor: AppColors.surfaceMuted,
      child: child,
    );
  }
}

/// A single placeholder block inside a skeleton.
///
/// Colour is irrelevant — [AppShimmer] paints over it — but it must be opaque
/// for the gradient to show.
class AppShimmerBox extends StatelessWidget {
  /// Creates a block the size of the content it stands in for — a text line
  /// by default.
  const AppShimmerBox({
    super.key,
    this.width,
    this.height = AppSizing.space12,
    this.radius = AppSizing.radiusSm,
    this.shape = BoxShape.rectangle,
  });

  /// Null stretches to the available width.
  final double? width;

  /// Match the line height of the text being previewed.
  final double height;

  /// Corner radius; ignored for a circle.
  final double radius;

  /// Rectangle, or circle for round avatars.
  final BoxShape shape;

  /// A square block, for avatar placeholders.
  const AppShimmerBox.square({
    required double size,
    super.key,
    this.radius = AppSizing.radiusMd,
  }) : width = size,
       height = size,
       shape = BoxShape.rectangle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        shape: shape,
        borderRadius: shape == BoxShape.circle
            ? null
            : BorderRadius.circular(radius),
      ),
    );
  }
}
