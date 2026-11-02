import 'package:equatable/equatable.dart';

/// The staff home's two counts (ADR 0028).
class QueueOverview extends Equatable {
  const QueueOverview({required this.inQueue, required this.assignedThisWeek});

  /// Cases assigned to the member; a super-admin's also counts every case
  /// under review.
  final int inQueue;

  /// Cases assigned to the member in the last seven days.
  final int assignedThisWeek;

  @override
  List<Object?> get props => [inQueue, assignedThisWeek];
}
