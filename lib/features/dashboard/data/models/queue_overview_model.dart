import '../../domain/entities/queue_overview.dart';
import 'metric_count.dart';

/// A staff member's `GET /dashboard/metrics` `data`. `meta` (the window) is
/// not shown.
abstract final class QueueOverviewModel {
  static QueueOverview fromData(Object? data) {
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Expected staff metrics in "data".');
    }
    return QueueOverview(
      inQueue: metricCount(data['queue']),
      assignedThisWeek: metricCount(data['recent']),
    );
  }
}
