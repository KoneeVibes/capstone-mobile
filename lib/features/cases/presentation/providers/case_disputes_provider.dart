import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/navigation/app_session.dart';
import '../../domain/entities/case_dispute.dart';
import 'cases_providers.dart';

/// The disputes raised on one case, oldest first, keyed by case id
/// (`GET /dispute/case/{id}`).
class CaseDisputesNotifier extends AsyncNotifier<List<CaseDispute>> {
  CaseDisputesNotifier(this.caseId);

  final String caseId;

  @override
  Future<List<CaseDispute>> build() async {
    ref.watch(sessionProvider);
    final result = await ref
        .read(disputesRepositoryProvider)
        .fetchDisputes(caseId);
    return result.unwrapOrThrow();
  }

  /// Swaps in a dispute a write has just returned.
  void replaceDispute(CaseDispute updated) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData([
      for (final dispute in current)
        dispute.id == updated.id ? updated : dispute,
    ]);
  }
}

final caseDisputesProvider =
    AsyncNotifierProvider.family<
      CaseDisputesNotifier,
      List<CaseDispute>,
      String
    >(CaseDisputesNotifier.new);

/// Whether any dispute on the list is still waiting for an answer. The API
/// allows one open dispute per case.
bool hasOpenDispute(List<CaseDispute> disputes) =>
    disputes.any((dispute) => dispute.isOpen);
