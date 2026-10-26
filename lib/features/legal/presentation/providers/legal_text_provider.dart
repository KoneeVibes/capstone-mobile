import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/legal_repository.dart';
import '../../domain/legal_document.dart';

final legalRepositoryProvider = Provider<LegalRepository>(
  (ref) => LegalRepository(rootBundle),
);

/// One legal page's markdown. Public pages, so no session watch.
final legalTextProvider = FutureProvider.family<String, LegalDocument>(
  (ref, document) async =>
      (await ref.read(legalRepositoryProvider).read(document)).unwrapOrThrow(),
);
