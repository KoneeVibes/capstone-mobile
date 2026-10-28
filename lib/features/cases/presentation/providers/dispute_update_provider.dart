import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/media_picker.dart';
import 'case_disputes_provider.dart';
import 'cases_providers.dart';

/// Raising and declining disputes.
///
/// Works like `CaseUpdateNotifier`: returns whether the write succeeded and
/// holds a failure as an `AppFailure`. Taking a dispute in is a case write,
/// `CaseUpdateNotifier.takeInDispute`.
class DisputeUpdateNotifier extends AsyncNotifier<void> {
  @override
  void build() {}

  /// The response carries no record, so the case's list is read again.
  Future<bool> raise({
    required String caseId,
    required String title,
    required String description,
    List<PickedMedia> attachments = const [],
  }) async {
    state = const AsyncLoading<void>();
    final result = await ref
        .read(disputesRepositoryProvider)
        .raiseDispute(
          caseId: caseId,
          title: title,
          description: description,
          attachments: attachments,
        );

    return result.fold(
      onOk: (_) {
        state = const AsyncData<void>(null);
        ref.invalidate(caseDisputesProvider(caseId));
        return true;
      },
      onErr: (failure) {
        state = AsyncError<void>(failure, StackTrace.current);
        return false;
      },
    );
  }

  Future<bool> decline({
    required String caseId,
    required String disputeId,
    required String note,
  }) async {
    state = const AsyncLoading<void>();
    final result = await ref
        .read(disputesRepositoryProvider)
        .rejectDispute(disputeId: disputeId, note: note);

    return result.fold(
      onOk: (updated) {
        state = const AsyncData<void>(null);
        if (ref.exists(caseDisputesProvider(caseId))) {
          ref
              .read(caseDisputesProvider(caseId).notifier)
              .replaceDispute(updated);
        }
        return true;
      },
      onErr: (failure) {
        state = AsyncError<void>(failure, StackTrace.current);
        return false;
      },
    );
  }
}

final disputeUpdateProvider =
    AsyncNotifierProvider<DisputeUpdateNotifier, void>(
      DisputeUpdateNotifier.new,
    );
