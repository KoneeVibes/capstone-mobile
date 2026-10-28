import '../../../../core/utils/media_picker.dart';
import '../../../../core/utils/result.dart';
import '../entities/case_dispute.dart';

/// Dispute data access. Returns a [Result] and never throws, like
/// `CasesRepository`.
///
/// Taking a dispute in is not here: it is a case status write
/// (`CasesRepository.updateStatus` with `disputed`).
abstract class DisputesRepository {
  /// Every dispute on [caseId], oldest first; none is an empty list.
  Future<Result<List<CaseDispute>>> fetchDisputes(String caseId);

  /// Raises a dispute on a closed case. The API answers with no record.
  Future<Result<void>> raiseDispute({
    required String caseId,
    required String title,
    required String description,
    List<PickedMedia> attachments = const [],
  });

  /// Declines an open dispute with [note], returning the updated dispute.
  Future<Result<CaseDispute>> rejectDispute({
    required String disputeId,
    required String note,
  });
}
