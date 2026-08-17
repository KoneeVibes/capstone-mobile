import '../../../../core/utils/result.dart';
import '../entities/staff.dart';
import '../entities/staff_draft.dart';
import '../entities/staff_page.dart';

/// Staff data access.
///
/// Every method returns a [Result] and never throws: the implementation catches
/// at its boundary and converts through `ErrorHandler`, so callers cannot
/// forget the failure path or see a raw exception.
abstract class StaffRepository {
  Future<Result<StaffPage>> fetchStaff({required int page, required int perPage});

  Future<Result<Staff>> fetchStaffMember(String id);

  /// Creates a staff member.
  ///
  /// Resolves to `Ok(null)` rather than the new record: `POST /staff` returns
  /// no `data` node. Callers refresh the list instead.
  Future<Result<void>> createStaff(StaffDraft draft);

  Future<Result<Staff>> updateStaff({
    required String id,
    required StaffDraft draft,
  });

  /// Soft-deletes a staff member, setting their status to inactive.
  ///
  /// Named for what the API actually does. There is no endpoint that reverses
  /// this — reactivation happens in the web portal.
  Future<Result<Staff>> deactivateStaff(String id);
}
