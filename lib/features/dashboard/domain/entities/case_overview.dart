import 'package:equatable/equatable.dart';

import 'tracking_status.dart';

/// The client Home's four counts over their own cases.
///
/// `suspended` and statuses this build does not know count only towards
/// [total]: neither is ready, moving, or waiting on the client.
class CaseOverview extends Equatable {
  const CaseOverview({
    required this.total,
    required this.reportsReady,
    required this.inProgress,
    required this.needsInput,
  });

  factory CaseOverview.fromStatuses(Iterable<TrackingStatus> statuses) {
    var total = 0;
    var ready = 0;
    var moving = 0;
    var waiting = 0;
    for (final status in statuses) {
      total++;
      switch (status) {
        case TrackingStatus.closed:
          ready++;
        case TrackingStatus.paymentValidated ||
            TrackingStatus.assigned ||
            TrackingStatus.accepted ||
            TrackingStatus.underReview:
          moving++;
        // Unpaid, or stalled on something from the applicant.
        case TrackingStatus.submitted || TrackingStatus.pendingInformation:
          waiting++;
        case TrackingStatus.suspended || TrackingStatus.unknown:
          break;
      }
    }
    return CaseOverview(
      total: total,
      reportsReady: ready,
      inProgress: moving,
      needsInput: waiting,
    );
  }

  final int total;
  final int reportsReady;
  final int inProgress;
  final int needsInput;

  @override
  List<Object?> get props => [total, reportsReady, inProgress, needsInput];
}
