import '../../domain/entities/case.dart';
import '../../domain/entities/case_assignee.dart';

/// Case data access at the IO boundary.
///
/// Throws on failure — nothing here catches, so the repository can convert in
/// one place. `CasesRemoteDataSourceImpl` lets `DioException` propagate
/// untouched, exactly as `StaffRemoteDataSource` does. Its one deliberate
/// exception is resolving an assignee's name, a secondary read whose failure
/// costs a name on a row rather than the whole screen.
abstract class CasesDataSource {
  Future<List<Case>> fetchCases();

  Future<Case> fetchCase(String id);

  Future<List<CaseAssignee>> fetchAssignees();

  Future<Case> assignCase({required String caseId, required String assigneeId});
}
