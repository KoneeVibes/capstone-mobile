import '../../../../core/utils/result.dart';
import '../entities/tracked_case.dart';

abstract class DashboardRepository {
  /// A case's status and history by its tracking ID, e.g. `PI-URF8T7C2`.
  Future<Result<TrackedCase>> trackCase(String trackingId);
}
