/// Bundled asset paths. Keeps string literals out of widgets so a moved or
/// renamed file breaks in one place.
abstract final class AppAssets {
  const AppAssets._();

  static const String _images = 'assets/images';
  static const String _icons = 'assets/icons';
  static const String _legal = 'assets/legal';

  static const String logo = '$_images/logo.png';
  static const String appIcon = '$_icons/app-icon.png';

  static const String privacyPolicy = '$_legal/privacy_policy.md';
  static const String terms = '$_legal/terms.md';
}
