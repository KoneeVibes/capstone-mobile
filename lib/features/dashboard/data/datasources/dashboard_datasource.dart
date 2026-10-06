import '../../domain/entities/case_overview.dart';
import '../../domain/entities/tracked_case.dart';

/// Throws on failure; the repository converts.
abstract class DashboardDataSource {
  Future<TrackedCase> trackCase(String trackingId);

  /// Counts over every case the signed-in user can list.
  Future<CaseOverview> fetchOverview();
}
