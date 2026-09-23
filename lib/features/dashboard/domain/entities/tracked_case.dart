import 'package:equatable/equatable.dart';

import 'tracking_event.dart';
import 'tracking_status.dart';

/// A case as `GET /case/track/{trackingId}` reports it.
class TrackedCase extends Equatable {
  const TrackedCase({
    required this.trackingId,
    required this.status,
    this.history = const [],
    this.address,
    this.updatedAt,
  });

  final String trackingId;
  final TrackingStatus status;

  /// Oldest first, as the API sends it.
  final List<TrackingEvent> history;

  /// Not on the tracking response; joined from the case list.
  final String? address;

  final DateTime? updatedAt;

  Set<String> get assigneeIds => {
    for (final event in history)
      if (event.assigneeId != null) event.assigneeId!,
  };

  /// True when the event at [index] hands the case on rather than out.
  bool isReassignment(int index) =>
      history[index].status == TrackingStatus.assigned &&
      history
          .take(index)
          .any((event) => event.status == TrackingStatus.assigned);

  TrackedCase withDetails({
    String? address,
    Map<String, String> assigneeNames = const {},
  }) => TrackedCase(
    trackingId: trackingId,
    status: status,
    updatedAt: updatedAt,
    address: address,
    history: [
      for (final event in history)
        event.assigneeId == null
            ? event
            : event.withAssigneeName(assigneeNames[event.assigneeId]),
    ],
  );

  @override
  List<Object?> get props => [trackingId, status, history, address, updatedAt];
}
