import 'queue_status.dart';

/// The tabs above the staff queue. Each groups several statuses, so the list
/// stays short on a phone where nine separate tabs would not fit.
///
/// TODO(backend): confirm the grouping once the queue endpoint and the new
/// `disputed` status are real.
enum QueueFilter {
  all('All'),
  fresh('New'),
  assigned('Assigned'),
  closed('Closed');

  const QueueFilter(this.label);

  /// The chip's text.
  final String label;

  /// Whether [status] belongs under this tab.
  bool matches(QueueStatus status) => switch (this) {
    QueueFilter.all => true,
    QueueFilter.fresh =>
      status == QueueStatus.paymentValidated || status == QueueStatus.submitted,
    QueueFilter.assigned =>
      status == QueueStatus.assigned ||
          status == QueueStatus.accepted ||
          status == QueueStatus.underReview ||
          status == QueueStatus.pendingInformation,
    QueueFilter.closed =>
      status == QueueStatus.closed ||
          status == QueueStatus.suspended ||
          status == QueueStatus.disputed,
  };
}
