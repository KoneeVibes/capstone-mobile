import '../../../../core/utils/result.dart';
import '../entities/case_overview.dart';
import '../entities/tracked_case.dart';

abstract class DashboardRepository {
  /// A case's status and history by its tracking ID, e.g. `PI-URF8T7C2`.
  Future<Result<TrackedCase>> trackCase(String trackingId);

  /// The client Home's counts over the user's own cases.
  Future<Result<CaseOverview>> fetchOverview();
}
