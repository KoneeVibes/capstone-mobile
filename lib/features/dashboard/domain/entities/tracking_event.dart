import 'package:equatable/equatable.dart';

import 'tracking_status.dart';

/// One entry in a case's `statusHistory`.
class TrackingEvent extends Equatable {
  const TrackingEvent({
    required this.status,
    this.changedAt,
    this.assigneeId,
    this.assigneeName,
    this.note,
  });

  final TrackingStatus status;
  final DateTime? changedAt;
  final String? assigneeId;

  /// Resolved from the staff list; null when unassigned or not found.
  final String? assigneeName;

  final String? note;

  TrackingEvent withAssigneeName(String? name) => TrackingEvent(
    status: status,
    changedAt: changedAt,
    assigneeId: assigneeId,
    assigneeName: name,
    note: note,
  );

  @override
  List<Object?> get props => [
    status,
    changedAt,
    assigneeId,
    assigneeName,
    note,
  ];
}
