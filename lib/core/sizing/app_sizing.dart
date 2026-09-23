/// Spacing, radius and dimension scale.
///
/// Widgets reference these rather than literal numbers, so density can be
/// retuned in one place.
abstract final class AppSizing {
  const AppSizing._();

  // Spacing scale (4pt base).
  static const double space2 = 2;
  static const double space4 = 4;
  static const double space6 = 6;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;
  static const double space40 = 40;
  static const double space48 = 48;

  /// Standard horizontal inset for screen content.
  static const double screenPadding = space16;

  // Corner radii.
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radiusSheet = 24;
  static const double radiusPill = 999;

  // Icons.
  static const double iconXs = 14;
  static const double iconSm = 18;
  static const double iconMd = 20;
  static const double iconLg = 24;
  static const double iconXl = 32;

  // Controls.
  static const double buttonHeight = 52;
  static const double fieldHeight = 52;
  static const double searchFieldHeight = 48;
  static const double chipHeight = 26;
  static const double iconButtonSize = 40;

  // Avatars.
  static const double avatarSm = 32;
  static const double avatarMd = 48;
  static const double avatarLg = 64;

  static const double bottomNavHeight = 64;

  // Case tracking.
  static const double bannerIllustrationSize = 56;
  static const double timelineConnectorWidth = 2;

  /// Rendered width of the splash wordmark.
  ///
  /// The source art is 482 px wide, so this is about as wide as it can be
  /// drawn before a 3x screen has to stretch it (200 x 3 = 600 px, a 1.24x
  /// upscale), while still landing near the design's proportion on a
  /// 360-411 dp phone. Raise it if a larger export arrives.
  static const double splashLogoWidth = 200;

  // Borders and elevation.
  static const double borderWidth = 1;
  static const double borderWidthFocused = 1.5;
  static const double cardElevation = 0;

  /// Height of the drag handle on a bottom sheet.
  static const double sheetGrabberHeight = 4;
  static const double sheetGrabberWidth = 40;

  /// Fraction of screen height a bottom sheet may occupy.
  static const double sheetMaxHeightFactor = 0.9;

  /// Square side of the illustration block in empty and error states.
  static const double stateIconBox = 72;
}
