import '../../../../core/utils/error/error_handler.dart';
import '../../../../core/utils/error/failure_type.dart';
import '../../../../core/utils/media_picker.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/case.dart';
import '../../domain/entities/case_assignee.dart';
import '../../domain/entities/case_status.dart';
import '../../domain/repositories/cases_repository.dart';
import '../datasources/cases_datasource.dart';

/// Converts the datasource's exceptions into [Result] values.
///
/// This is the boundary the whole error contract rests on: it is the only place
/// in the feature that catches, and it always converts through [ErrorHandler].
class CasesRepositoryImpl implements CasesRepository {
  const CasesRepositoryImpl(this._source);

  final CasesDataSource _source;

  @override
  Future<Result<List<Case>>> fetchCases() async {
    try {
      return Ok(await _source.fetchCases());
    } on Object catch (error, stackTrace) {
      final failure = ErrorHandler.from(error, stackTrace);

      // A list endpoint answering 404 means "none", not "broken" — the staff
      // API does exactly this. An empty inbox is not an error screen.
      if (failure.type == FailureType.notFound) return const Ok([]);

      return Err(failure);
    }
  }

  @override
  Future<Result<Case>> fetchCase(String id) =>
      _guard(() => _source.fetchCase(id));

  @override
  Future<Result<List<Case>>> searchCases(String query) =>
      _guard(() => _source.searchCases(query));

  @override
  Future<Result<List<CaseAssignee>>> fetchAssignees() =>
      _guard(_source.fetchAssignees);

  @override
  Future<Result<Case>> assignCase({
    required String caseId,
    required String assigneeId,
  }) =>
      _guard(() => _source.assignCase(caseId: caseId, assigneeId: assigneeId));

  @override
  Future<Result<Case>> updateStatus({
    required String caseId,
    required CaseStatus status,
  }) => _guard(() => _source.updateStatus(caseId: caseId, status: status));

  @override
  Future<Result<Case>> suspendCase({required String caseId}) =>
      _guard(() => _source.suspendCase(caseId: caseId));

  @override
  Future<Result<Case>> submitReport({
    required String caseId,
    required List<PickedMedia> files,
  }) => _guard(() => _source.submitReport(caseId: caseId, files: files));

  /// Runs [action], mapping anything thrown into an [Err].
  static Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Ok(await action());
    } on Object catch (error, stackTrace) {
      return Err(ErrorHandler.from(error, stackTrace));
    }
  }
}
