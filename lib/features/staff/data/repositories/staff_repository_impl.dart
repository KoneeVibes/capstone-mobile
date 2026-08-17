import '../../../../core/utils/error/error_handler.dart';
import '../../../../core/utils/error/failure_type.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/staff.dart';
import '../../domain/entities/staff_draft.dart';
import '../../domain/entities/staff_page.dart';
import '../../domain/repositories/staff_repository.dart';
import '../datasources/staff_remote_datasource.dart';

/// Converts the datasource's exceptions into [Result] values.
///
/// This is the boundary the whole error contract rests on: it is the only place
/// in the feature that catches, and it always converts through [ErrorHandler].
class StaffRepositoryImpl implements StaffRepository {
  const StaffRepositoryImpl(this._remote);

  final StaffRemoteDataSource _remote;

  @override
  Future<Result<StaffPage>> fetchStaff({
    required int page,
    required int perPage,
  }) async {
    try {
      final result = await _remote.fetchStaff(page: page, perPage: perPage);
      return Ok(result);
    } on Object catch (error, stackTrace) {
      final failure = ErrorHandler.from(error, stackTrace);

      // The API documents 404 on the list endpoint as "No staff members
      // found", which is an empty result rather than an error. Showing an
      // error screen on a fresh install would be wrong.
      if (failure.type == FailureType.notFound) {
        return const Ok(StaffPage.empty());
      }

      return Err(failure);
    }
  }

  @override
  Future<Result<Staff>> fetchStaffMember(String id) =>
      _guard(() => _remote.fetchStaffMember(id));

  @override
  Future<Result<void>> createStaff(StaffDraft draft) =>
      _guard(() => _remote.createStaff(draft));

  @override
  Future<Result<Staff>> updateStaff({
    required String id,
    required StaffDraft draft,
  }) => _guard(() => _remote.updateStaff(id: id, draft: draft));

  @override
  Future<Result<Staff>> deactivateStaff(String id) =>
      _guard(() => _remote.deactivateStaff(id));

  /// Runs [action], mapping anything thrown into an [Err].
  static Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Ok(await action());
    } on Object catch (error, stackTrace) {
      return Err(ErrorHandler.from(error, stackTrace));
    }
  }
}
