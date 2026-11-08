import '../../domain/entities/case_overview.dart';
import '../../domain/entities/queue_overview.dart';
import '../../domain/entities/recent_search.dart';
import '../../domain/entities/tracked_case.dart';

/// Throws on failure; the repository converts.
abstract class DashboardDataSource {
  Future<TrackedCase> trackCase(String trackingId);

  /// The newest tracking IDs in the signed-in user's search history.
  Future<List<RecentSearch>> fetchRecentSearches({required int limit});

  /// The signed-in client's counts; the server picks the shape by token.
  Future<CaseOverview> fetchClientOverview();

  /// The signed-in staff member's counts.
  Future<QueueOverview> fetchStaffOverview();
}
