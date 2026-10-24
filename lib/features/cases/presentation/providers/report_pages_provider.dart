import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/document_preview.dart';

/// One report file's pages, drawn for the review view, by URL.
///
/// Auto-disposed, so the page images go when the view closes. Never retried:
/// a file the host refuses comes back refused, and the view offers its own
/// retry where one could help.
final reportPagesProvider = FutureProvider.autoDispose
    .family<List<Uint8List>, String>(
      (ref, url) async =>
          (await ref.watch(documentPreviewProvider).pagesOf(url))
              .unwrapOrThrow(),
      retry: (_, _) => null,
    );
