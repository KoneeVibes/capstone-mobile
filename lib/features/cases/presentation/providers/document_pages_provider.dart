import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/document_preview.dart';

/// One case file's pages, drawn in the app, by URL: a property document or a
/// report file.
///
/// Auto-disposed, so the page images go when the view closes. Never retried:
/// a file the host refuses comes back refused, and the view offers its own
/// retry where one could help.
final documentPagesProvider = FutureProvider.autoDispose
    .family<List<Uint8List>, String>(
      (ref, url) async =>
          (await ref.watch(documentPreviewProvider).pagesOf(url))
              .unwrapOrThrow(),
      retry: (_, _) => null,
    );
