import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/media_picker.dart';
import '../../domain/entities/case_dispute.dart';

/// The disputes raised on one case, newest last, keyed by case id.
///
/// Mock and in memory. Deliberately does not watch the session, so a dispute
/// raised as a client can be answered as staff on the same device.
///
/// TODO(backend): load, raise (with evidence upload) and respond through the
/// dispute endpoints once they exist.
class CaseDisputesNotifier extends Notifier<List<CaseDispute>> {
  CaseDisputesNotifier(this.caseId);

  final String caseId;

  @override
  List<CaseDispute> build() => const [];

  CaseDispute raise({
    required String title,
    required String description,
    List<PickedMedia> evidence = const [],
  }) {
    // Disputes are only ever appended, so the count is a unique id.
    final dispute = CaseDispute(
      id: '$caseId-${state.length + 1}',
      title: title.trim(),
      description: description.trim(),
      evidence: evidence,
      raisedAt: DateTime.now(),
    );
    state = [...state, dispute];
    return dispute;
  }

  void takeIn(String id) => _update(id, (d) => d.takeIn(DateTime.now()));

  void decline(String id, String note) =>
      _update(id, (d) => d.decline(DateTime.now(), note.trim()));

  /// Only an open dispute can be answered; anything else is left alone.
  void _update(String id, CaseDispute Function(CaseDispute) change) {
    state = [
      for (final dispute in state)
        dispute.id == id && dispute.isOpen ? change(dispute) : dispute,
    ];
  }
}

final caseDisputesProvider =
    NotifierProvider.family<CaseDisputesNotifier, List<CaseDispute>, String>(
      CaseDisputesNotifier.new,
    );
