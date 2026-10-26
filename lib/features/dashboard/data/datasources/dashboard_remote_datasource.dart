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

  /// The default list, which includes closed cases (ADR 0023). A client with
  /// no cases at all gets a 404 "Cases not found" — that is zero, not a
  /// failure.
  @override
  Future<CaseOverview> fetchOverview() async {
    try {
      final rows = await _client.getAllPages<CaseStatusRowModel>(
        ApiEndpoints.cases,
        CaseStatusRowModel.listFromJson,
      );
      return CaseOverview.fromStatuses(rows.map((row) => row.status));
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return CaseOverview.fromStatuses(const []);
      }
      rethrow;
    }
  }

  /// `GET /case/{_id}` 404s and the list ignores `trackingId`/`search`, so the
  /// list is searched.
  Future<String?> _addressOf(String trackingId) async {
    try {
      final rows = await _client.getAllPages<CaseAddressModel>(
        ApiEndpoints.cases,
        CaseAddressModel.listFromJson,
      );
      return rows
          .where((row) => row.trackingId == trackingId)
          .firstOrNull
          ?.address;
    } on Object {
      return null;
    }
  }

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
