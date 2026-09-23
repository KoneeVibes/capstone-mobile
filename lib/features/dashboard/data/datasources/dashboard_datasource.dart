import '../../domain/entities/tracked_case.dart';

/// Throws on failure; the repository converts.
abstract class DashboardDataSource {
  Future<TrackedCase> trackCase(String trackingId);
}
