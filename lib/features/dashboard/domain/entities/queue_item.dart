import 'package:equatable/equatable.dart';

import 'queue_status.dart';

/// One card in the staff "My queue" list.
///
/// All fields are mock for now; the real shape arrives with the endpoint.
///
/// TODO(backend): populate from the staff-queue endpoint (reference, property,
/// assignee and a real due date in place of [dueInDays]).
class QueueItem extends Equatable {
  const QueueItem({
    required this.reference,
    required this.propertyName,
    required this.partyName,
    required this.status,
    required this.dueInDays,
  });

  /// Human reference shown above the card, e.g. `SLP-2291`. Stands in as the id
  /// the action buttons route with until real ids arrive.
  final String reference;

  final String propertyName;

  /// Whoever the card is about — the applicant, or the member it is assigned to.
  final String partyName;

  final QueueStatus status;

  /// Days until the work is due; negative is overdue, zero is today.
  final int dueInDays;

  @override
  List<Object?> get props => [
    reference,
    propertyName,
    partyName,
    status,
    dueInDays,
  ];
}
