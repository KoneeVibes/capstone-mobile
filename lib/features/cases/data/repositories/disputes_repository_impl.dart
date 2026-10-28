import '../../../../core/utils/error/error_handler.dart';
import '../../../../core/utils/error/failure_type.dart';
import '../../../../core/utils/media_picker.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/case_dispute.dart';
import '../../domain/repositories/disputes_repository.dart';
import '../datasources/disputes_datasource.dart';

/// Converts the datasource's exceptions into [Result] values through
/// [ErrorHandler]; the only place disputes catch.
class DisputesRepositoryImpl implements DisputesRepository {
  const DisputesRepositoryImpl(this._source);

  final DisputesDataSource _source;

  @override
  Future<Result<List<CaseDispute>>> fetchDisputes(String caseId) async {
    final result = await _guard(() => _source.fetchDisputes(caseId));
    // "Case disputes not found" is the API's answer for a case with none.
    if (result case Err(
      :final failure,
    ) when failure.type == FailureType.notFound) {
      return const Ok([]);
    }
    return result;
  }

  @override
  Future<Result<void>> raiseDispute({
    required String caseId,
    required String title,
    required String description,
    List<PickedMedia> attachments = const [],
  }) => _guard(
    () => _source.raiseDispute(
      caseId: caseId,
      title: title,
      description: description,
      attachments: attachments,
    ),
  );

  @override
  Future<Result<CaseDispute>> rejectDispute({
    required String disputeId,
    required String note,
  }) => _guard(() => _source.rejectDispute(disputeId: disputeId, note: note));

  static Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Ok(await action());
    } on Object catch (error, stackTrace) {
      return Err(ErrorHandler.from(error, stackTrace));
    }
  }
}
