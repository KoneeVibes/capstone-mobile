import '../../../core/constants/app_assets.dart';

/// The legal pages bundled with the app, as markdown in `assets/legal/`.
enum LegalDocument {
  terms(AppAssets.terms),
  privacyPolicy(AppAssets.privacyPolicy);

  const LegalDocument(this.asset);

  final String asset;
}
