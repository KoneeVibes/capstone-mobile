import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/case_overview.dart';
import '../../domain/entities/queue_overview.dart';
import '../../domain/entities/recent_search.dart';
import '../../domain/entities/tracked_case.dart';
import '../models/case_overview_model.dart';
import '../models/queue_overview_model.dart';
import '../models/recent_search_model.dart';
import '../models/tracked_case_model.dart';
import 'dashboard_datasource.dart';

class DashboardRemoteDataSourceImpl implements DashboardDataSource {
  const DashboardRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  /// Room for the free-text searches [RecentSearchModel] drops.
  static const int _historyPageSize = 20;

  @override
  Future<TrackedCase> trackCase(String trackingId) async {
    final response = await _client.get<TrackedCase>(
      ApiEndpoints.trackCase(trackingId),
      decoder: TrackedCaseModel.fromData,
    );
    return response.data;
  }

  /// One page: the server sorts by last use and only the newest are shown.
  @override
  Future<List<RecentSearch>> fetchRecentSearches({required int limit}) async {
    final response = await _client.get<List<RecentSearch>>(
      ApiEndpoints.searchHistory,
      queryParameters: const {'page': 1, 'perPage': _historyPageSize},
      decoder: RecentSearchModel.listFromJson,
    );
    return response.data.take(limit).toList(growable: false);
  }

  @override
  Future<CaseOverview> fetchClientOverview() async {
    final response = await _client.get<CaseOverview>(
      ApiEndpoints.dashboardMetrics,
      decoder: CaseOverviewModel.fromData,
    );
    return response.data;
  }

  @override
  Future<QueueOverview> fetchStaffOverview() async {
    final response = await _client.get<QueueOverview>(
      ApiEndpoints.dashboardMetrics,
      decoder: QueueOverviewModel.fromData,
    );
    return response.data;
  }
}
