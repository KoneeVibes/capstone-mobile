import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_pagination.dart';
import '../../domain/entities/case_overview.dart';
import '../../domain/entities/tracked_case.dart';
import '../models/case_address_model.dart';
import '../models/case_status_row_model.dart';
import '../models/staff_name_model.dart';
import '../models/tracked_case_model.dart';
import 'dashboard_datasource.dart';

class DashboardRemoteDataSourceImpl implements DashboardDataSource {
  const DashboardRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  /// The tracking call may throw; the address and name joins never do.
  @override
  Future<TrackedCase> trackCase(String trackingId) async {
    final response = await _client.get<TrackedCase>(
      ApiEndpoints.trackCase(trackingId),
      decoder: TrackedCaseModel.fromData,
    );
    final tracked = response.data;

    final (address, names) = await (
      _addressOf(tracked.trackingId),
      tracked.assigneeIds.isEmpty
          ? Future.value(const <String, String>{})
          : _staffNames(),
    ).wait;

    return tracked.withDetails(address: address, assigneeNames: names);
  }

  /// The default list plus `filter=closed`, merged by id as the cases list
  /// does. A client with no cases at all gets a 404 "Cases not found" — that
  /// is zero, not a failure.
  @override
  Future<CaseOverview> fetchOverview() async {
    // In turn, not `.wait`: a record wait wraps failures in a
    // ParallelWaitError, which ErrorHandler cannot read.
    final active = await _rowsOrNone(const {});
    final closed = await _rowsOrNone(const {'filter': 'closed'});
    final ids = <String>{};
    final rows = [
      ...active,
      ...closed,
    ].where((row) => row.id == null || ids.add(row.id!));
    return CaseOverview.fromStatuses(rows.map((row) => row.status));
  }

  Future<List<CaseStatusRowModel>> _rowsOrNone(
    Map<String, dynamic> query,
  ) async {
    try {
      return await _client.getAllPages<CaseStatusRowModel>(
        ApiEndpoints.cases,
        CaseStatusRowModel.listFromJson,
        query: query,
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return const [];
      rethrow;
    }
  }

  /// `GET /case/{_id}` 404s and the list ignores `trackingId`/`search`, so the
  /// list is searched. Closed cases need their own `filter=closed` request.
  Future<String?> _addressOf(String trackingId) async {
    try {
      final active = await _client.getAllPages<CaseAddressModel>(
        ApiEndpoints.cases,
        CaseAddressModel.listFromJson,
      );
      final match =
          _find(active, trackingId) ?? _find(await _closedCases(), trackingId);
      return match?.address;
    } on Object {
      return null;
    }
  }

  Future<List<CaseAddressModel>> _closedCases() async {
    try {
      return await _client.getAllPages<CaseAddressModel>(
        ApiEndpoints.cases,
        CaseAddressModel.listFromJson,
        query: const {'filter': 'closed'},
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return const [];
      rethrow;
    }
  }

  static CaseAddressModel? _find(
    List<CaseAddressModel> rows,
    String trackingId,
  ) => rows.where((row) => row.trackingId == trackingId).firstOrNull;

  Future<Map<String, String>> _staffNames() async {
    try {
      final staff = await _client.getAllPages<StaffNameModel>(
        ApiEndpoints.staff,
        StaffNameModel.listFromJson,
      );
      return {
        for (final person in staff)
          if (person.name.isNotEmpty) person.id: person.name,
      };
    } on Object {
      return const {};
    }
  }
}
