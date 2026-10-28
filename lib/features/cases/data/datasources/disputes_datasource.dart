import '../../../../core/utils/media_picker.dart';
import '../../domain/entities/case_dispute.dart';

/// Dispute data access at the IO boundary. Throws on failure; the repository
/// converts.
abstract class DisputesDataSource {
  Future<List<CaseDispute>> fetchDisputes(String caseId);

  Future<void> raiseDispute({
    required String caseId,
    required String title,
    required String description,
    required List<PickedMedia> attachments,
  });

  Future<CaseDispute> rejectDispute({
    required String disputeId,
    required String note,
  });
}
