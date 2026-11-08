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

  /// As the server names the assignee; null when unassigned.
  final String? assigneeName;

  final String? note;

  @override
  List<Object?> get props => [
    status,
    changedAt,
    assigneeId,
    assigneeName,
    note,
  ];
}
