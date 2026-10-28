import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/media_picker.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/case.dart';
import '../../domain/entities/case_status.dart';
import 'case_detail_provider.dart';
import 'case_disputes_provider.dart';
import 'cases_list_provider.dart';
import 'cases_providers.dart';

/// Status changes and report uploads.
///
/// Works like `CaseAssignmentNotifier`: returns whether the write succeeded,
/// holds a failure as an `AppFailure`, and puts the returned case into the
/// screens holding it rather than re-reading.
class CaseUpdateNotifier extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<bool> accept(String caseId) => _move(caseId, CaseStatus.accepted);

  Future<bool> suspend(String caseId) => _write(
    caseId,
    () => ref.read(casesRepositoryProvider).suspendCase(caseId: caseId),
  );

  /// Accepting a report closes the case and releases the report to the client.
  Future<bool> close(String caseId) => _move(caseId, CaseStatus.closed);

  /// Taking a client's dispute in: the case moves to `disputed` and its report
  /// has to be submitted again. The disputes are re-read for the server's say
  /// on the dispute itself (ADR 0025).
  Future<bool> takeInDispute(String caseId) async {
    final moved = await _move(caseId, CaseStatus.disputed);
    if (moved) ref.invalidate(caseDisputesProvider(caseId));
    return moved;
  }

  Future<bool> submitReport(String caseId, List<PickedMedia> files) => _write(
    caseId,
    () => ref
        .read(casesRepositoryProvider)
        .submitReport(caseId: caseId, files: files),
  );

  Future<bool> _move(String caseId, CaseStatus status) => _write(
    caseId,
    () => ref
        .read(casesRepositoryProvider)
        .updateStatus(caseId: caseId, status: status),
  );

  Future<bool> _write(
    String caseId,
    Future<Result<Case>> Function() request,
  ) async {
    state = const AsyncLoading<void>();
    final result = await request();

    return result.fold(
      onOk: (updated) {
        state = const AsyncData<void>(null);
        // Only screens already holding the case: reading a provider that does
        // not exist yet would start a fetch just to be overwritten.
        if (ref.exists(caseDetailProvider(caseId))) {
          ref.read(caseDetailProvider(caseId).notifier).replaceWith(updated);
        }
        if (ref.exists(casesListProvider)) {
          ref.read(casesListProvider.notifier).replaceCase(updated);
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

final caseUpdateProvider = AsyncNotifierProvider<CaseUpdateNotifier, void>(
  CaseUpdateNotifier.new,
);
