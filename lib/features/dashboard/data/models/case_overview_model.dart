import '../../domain/entities/case_overview.dart';
import 'metric_count.dart';

/// A client's `GET /dashboard/metrics` `data`.
abstract final class CaseOverviewModel {
  static CaseOverview fromData(Object? data) {
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Expected client metrics in "data".');
    }
    return CaseOverview(
      total: metricCount(data['totalSearches']),
      reportsReady: metricCount(data['reportsReady']),
      inProgress: metricCount(data['inProgress']),
      needsInput: metricCount(data['needsYourInput']),
    );
  }
}
