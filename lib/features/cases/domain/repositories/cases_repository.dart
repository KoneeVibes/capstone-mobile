import '../../../../core/utils/result.dart';
import '../entities/case.dart';
import '../entities/case_assignee.dart';

/// Case data access.
///
/// Every method returns a [Result] and never throws: the implementation catches
/// at its boundary and converts through `ErrorHandler`, so callers cannot
/// forget the failure path or see a raw exception.
abstract class CasesRepository {
  /// Every case the signed-in user can see, in every status.
  ///
  /// Unpaginated by contract. The list filters and counts client side (`2 of 5
  /// cases`), which a page at a time cannot answer, so the implementation walks
  /// the endpoint's pages to the end rather than returning the first one. The
  /// API can filter and page server side; move to it when volume demands it,
  /// and expect the footer's two numbers to need rethinking when you do.
  Future<Result<List<Case>>> fetchCases();

  Future<Result<Case>> fetchCase(String id);

  /// The team members a case may be given to.
  Future<Result<List<CaseAssignee>>> fetchAssignees();

  /// Assigns or re-assigns [caseId], returning the updated case.
  ///
  /// One method for both: re-assignment is the same write with a different
  /// current holder, and the API is not expected to distinguish them.
  Future<Result<Case>> assignCase({
    required String caseId,
    required String assigneeId,
  });
}
