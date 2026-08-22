import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/case.dart';
import 'cases_providers.dart';

/// One case, by id. Backs the detail screen.
///
/// A family rather than a lookup into the list, so the screen still works on a
/// cold start from a deep link, when no list has been loaded.
///
/// A class notifier rather than a `FutureProvider.family` because a successful
/// write has to be able to put its result back — see [replaceWith]. Note that
/// the id arrives through the constructor: a family notifier without codegen
/// takes its argument there, and `build()` takes none.
class CaseDetailNotifier extends AsyncNotifier<Case> {
  CaseDetailNotifier(this.caseId);

  final String caseId;

  @override
  Future<Case> build() async {
    final result = await ref.read(casesRepositoryProvider).fetchCase(caseId);
    // Throws the AppFailure, which Riverpod stores as AsyncValue.error. The UI
    // reads it back through AsyncValueFailureX.failure, so it can only ever be
    // an AppFailure — never a raw exception.
    return result.unwrapOrThrow();
  }

  /// Swaps in a case a write has just returned.
  ///
  /// Exists so a successful write does not have to be followed by a read. The
  /// response already carries the server's own updated record; re-fetching
  /// would leave the screen contradicting its own confirmation for the length
  /// of a round trip, which on a cold-starting host reads as a silent failure.
  void replaceWith(Case value) => state = AsyncData(value);
}

final caseDetailProvider =
    AsyncNotifierProvider.family<CaseDetailNotifier, Case, String>(
      CaseDetailNotifier.new,
    );
