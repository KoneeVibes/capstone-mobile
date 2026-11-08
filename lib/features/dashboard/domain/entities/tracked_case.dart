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

  /// The free-text `propertyAddress`.
  final String? address;

  final DateTime? updatedAt;

  /// True when the event at [index] hands the case on rather than out.
  bool isReassignment(int index) =>
      history[index].status == TrackingStatus.assigned &&
      history
          .take(index)
          .any((event) => event.status == TrackingStatus.assigned);

  @override
  List<Object?> get props => [trackingId, status, history, address, updatedAt];
}
