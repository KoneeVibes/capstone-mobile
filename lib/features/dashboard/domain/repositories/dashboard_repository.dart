import '../../../../core/utils/result.dart';
import '../entities/case_overview.dart';
import '../entities/queue_overview.dart';
import '../entities/recent_search.dart';
import '../entities/tracked_case.dart';

abstract class DashboardRepository {
  /// A case's status and history by its tracking ID, e.g. `PI-URF8T7C2`.
  Future<Result<TrackedCase>> trackCase(String trackingId);

  /// Up to [limit] tracking IDs the user looked up, newest first. A signed-in
  /// [trackCase] adds to them.
  Future<Result<List<RecentSearch>>> fetchRecentSearches({required int limit});

  /// The client Home's counts over the user's own cases.
  Future<Result<CaseOverview>> fetchClientOverview();

  /// The staff home's counts.
  Future<Result<QueueOverview>> fetchStaffOverview();
}
