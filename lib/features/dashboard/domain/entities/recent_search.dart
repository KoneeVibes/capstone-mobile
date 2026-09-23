import 'package:equatable/equatable.dart';

import 'tracked_case.dart';
import 'tracking_status.dart';

/// A successful lookup, as it stood when it was searched.
class RecentSearch extends Equatable {
  const RecentSearch({
    required this.trackingId,
    required this.status,
    this.address,
  });

  RecentSearch.fromTracked(TrackedCase value)
    : trackingId = value.trackingId,
      status = value.status,
      address = value.address;

  final String trackingId;
  final TrackingStatus status;
  final String? address;

  @override
  List<Object?> get props => [trackingId, status, address];
}
