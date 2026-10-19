import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/queue_item.dart';
import '../../domain/entities/queue_status.dart';

/// The staff member's queue.
///
/// A fixed mock list for now — one card per status so every state and action is
/// visible. The UI is built against this shape so wiring the endpoint is a
/// swap, not a rewrite.
///
/// TODO(backend): replace with the staff-queue endpoint (a repository + an
/// `AsyncNotifier`, like `caseDetailProvider`).
final staffQueueProvider = Provider<List<QueueItem>>((ref) {
  return const [
    QueueItem(
      reference: 'SLP-2291',
      propertyName: 'Block C, Ikoyi Crescent',
      partyName: 'Kolajo Mike',
      status: QueueStatus.paymentValidated,
      dueInDays: -1,
    ),
    QueueItem(
      reference: 'SLP-2292',
      propertyName: 'Block C, Ikoyi Crescent',
      partyName: 'Kolajo Mike',
      status: QueueStatus.assigned,
      dueInDays: 1,
    ),
    QueueItem(
      reference: 'SLP-2293',
      propertyName: 'Block C, Ikoyi Crescent',
      partyName: 'Kolajo Mike',
      status: QueueStatus.accepted,
      dueInDays: 2,
    ),
    QueueItem(
      reference: 'SLP-2294',
      propertyName: 'Block C, Ikoyi Crescent',
      partyName: 'Kolajo Mike',
      status: QueueStatus.underReview,
      dueInDays: 0,
    ),
    QueueItem(
      reference: 'SLP-2295',
      propertyName: 'Block C, Ikoyi Crescent',
      partyName: 'Kolajo Mike',
      status: QueueStatus.pendingInformation,
      dueInDays: 0,
    ),
    QueueItem(
      reference: 'SLP-2296',
      propertyName: 'Block C, Ikoyi Crescent',
      partyName: 'Kolajo Mike',
      status: QueueStatus.submitted,
      dueInDays: 3,
    ),
    QueueItem(
      reference: 'SLP-2297',
      propertyName: 'Block C, Ikoyi Crescent',
      partyName: 'Kolajo Mike',
      status: QueueStatus.disputed,
      dueInDays: 2,
    ),
    QueueItem(
      reference: 'SLP-2298',
      propertyName: 'Block C, Ikoyi Crescent',
      partyName: 'Kolajo Mike',
      status: QueueStatus.suspended,
      dueInDays: 0,
    ),
    QueueItem(
      reference: 'SLP-2299',
      propertyName: 'Block C, Ikoyi Crescent',
      partyName: 'Kolajo Mike',
      status: QueueStatus.closed,
      dueInDays: 1,
    ),
  ];
});
