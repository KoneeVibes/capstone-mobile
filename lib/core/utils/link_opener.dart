import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'error/app_failures.dart';
import 'result.dart';

/// The platform call [LinkOpener] sits on.
///
/// Separated so tests can open a link without touching a platform channel,
/// exactly as `MediaPickerBackend` does for the pickers.
abstract class LinkLauncherBackend {
  Future<bool> launch(Uri uri);
}

/// Opens links that belong outside the app.
///
/// Features call this, never url_launcher directly — the same rule that keeps
/// plugin calls out of features for picking files. One place decides what a
/// failure to open reads as, and no screen ever sees a `PlatformException`.
///
/// Returns a [Result] so the caller handles the failure path deliberately.
class LinkOpener {
  const LinkOpener(this._backend);

  final LinkLauncherBackend _backend;

  /// Hands [url] to the browser or whichever app claims it.
  ///
  /// A URL that will not parse is rejected here rather than passed on: the
  /// plugin's own behaviour on a malformed URI differs by platform, and a
  /// document link the API sent broken is not something a retry will fix.
  Future<Result<void>> open(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !_isOpenable(uri)) {
      return const Err<void>(AppFailures.linkNotOpenable);
    }

    try {
      final launched = await _backend.launch(uri);
      return launched
          ? const Ok<void>(null)
          : const Err<void>(AppFailures.linkNotOpenable);
    } on Object {
      // A PlatformException from the plugin, most often because nothing on the
      // device handles the scheme. Converted here so it cannot reach a widget.
      return const Err<void>(AppFailures.linkNotOpenable);
    }
  }
}

/// Schemes that address something without a host: `mailto:a@b.c`, `tel:123`.
const Set<String> _hostlessSchemes = {'mailto', 'tel'};

bool _isOpenable(Uri uri) {
  if (!uri.hasScheme) return false;
  if (uri.hasAuthority) return true;
  return _hostlessSchemes.contains(uri.scheme) && uri.path.isNotEmpty;
}

/// Opens through url_launcher, in whatever app the device uses for the link.
class UrlLauncherBackend implements LinkLauncherBackend {
  const UrlLauncherBackend();

  @override
  Future<bool> launch(Uri uri) =>
      // externalApplication rather than an in-app web view: a PDF, an email
      // address or a phone number belongs in the device's own app for it.
      launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// Override this in tests to open links without touching platform channels.
final linkOpenerProvider = Provider<LinkOpener>(
  (ref) => const LinkOpener(UrlLauncherBackend()),
);
