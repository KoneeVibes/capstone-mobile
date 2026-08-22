import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'case_detail_provider.dart';
import 'cases_list_provider.dart';
import 'cases_providers.dart';

/// Assignment and re-assignment.
///
/// Returns whether it succeeded, so the calling sheet can decide to close or
/// stay open. On failure the state holds an `AppFailure`, read back with
/// `AsyncValueFailureX.failure` — the raw exception never reaches the widget.
class CaseAssignmentNotifier extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<bool> assign({
    required String caseId,
    required String assigneeId,
  }) async {
    state = const AsyncLoading<void>();

    final result = await ref
        .read(casesRepositoryProvider)
        .assignCase(caseId: caseId, assigneeId: assigneeId);

    return result.fold(
      onOk: (updated) {
        state = const AsyncData<void>(null);

        // Both screens are corrected from the record the write returned, not
        // by re-reading. Re-reading would leave the detail screen showing
        // "Not assigned yet" underneath its own "assigned" confirmation until
        // the round trip finished — seconds on this host, and long enough to
        // read as a silent failure.
        ref.read(caseDetailProvider(caseId).notifier).replaceWith(updated);
        ref.read(casesListProvider.notifier).replaceCase(updated);
        return true;
      },
      onErr: (failure) {
        state = AsyncError<void>(failure, StackTrace.current);
        return false;
      },
    );
  }
}

final caseAssignmentProvider =
    AsyncNotifierProvider<CaseAssignmentNotifier, void>(
      CaseAssignmentNotifier.new,
    );
