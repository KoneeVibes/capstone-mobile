import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/staff.dart';
import '../../domain/entities/staff_draft.dart';
import '../../domain/entities/staff_page.dart';
import '../models/staff_model.dart';

/// Network access for staff records.
///
/// Throws on failure — `DioException` is allowed to propagate untouched so the
/// repository can convert it in one place. Nothing here catches.
abstract class StaffRemoteDataSource {
  Future<StaffPage> fetchStaff({required int page, required int perPage});

  Future<Staff> fetchStaffMember(String id);

  /// Returns nothing: unlike every other endpoint, `POST /staff` replies with
  /// `{status, message}` and no `data` node, so there is no record to decode.
  Future<void> createStaff(StaffDraft draft);

  Future<Staff> updateStaff({required String id, required StaffDraft draft});

  Future<Staff> deactivateStaff(String id);
}

class StaffRemoteDataSourceImpl implements StaffRemoteDataSource {
  const StaffRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<StaffPage> fetchStaff({
    required int page,
    required int perPage,
  }) async {
    final response = await _client.get<List<Staff>>(
      ApiEndpoints.staff,
      queryParameters: {'page': page, 'perPage': perPage},
      decoder: StaffModel.listFromJson,
    );
    return StaffPage(items: response.data, meta: response.meta);
  }

  @override
  Future<Staff> fetchStaffMember(String id) async {
    final response = await _client.get<Staff>(
      ApiEndpoints.staffById(id),
      decoder: StaffModel.fromData,
    );
    return response.data;
  }

  @override
  Future<void> createStaff(StaffDraft draft) async {
    // No decoder: a 201 carries only `{status, message}`. Asking for a record
    // here would throw on a create that actually succeeded, and the caller
    // would retry into a duplicate-email conflict.
    await _client.post<void>(
      ApiEndpoints.staff,
      data: await StaffModel.formDataFrom(draft),
      decoder: (_) {},
    );
  }

  @override
  Future<Staff> updateStaff({
    required String id,
    required StaffDraft draft,
  }) async {
    final response = await _client.put<Staff>(
      ApiEndpoints.staffById(id),
      data: await StaffModel.formDataFrom(draft),
      decoder: StaffModel.fromData,
    );
    return response.data;
  }

  @override
  Future<Staff> deactivateStaff(String id) async {
    final response = await _client.delete<Staff>(
      ApiEndpoints.staffById(id),
      decoder: StaffModel.fromData,
    );
    return response.data;
  }
}
