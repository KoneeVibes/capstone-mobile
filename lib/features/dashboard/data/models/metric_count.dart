/// A count from `GET /dashboard/metrics`; anything missing or not a
/// non-negative number reads as zero.
int metricCount(Object? value) =>
    value is num && value >= 0 ? value.toInt() : 0;
