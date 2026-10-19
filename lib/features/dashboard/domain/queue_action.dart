import 'entities/queue_status.dart';

/// What a queue card's button does when tapped.
enum QueueActionKind {
  /// Open the case detail screen so the member can carry the work out there.
  detail,

  /// The one confirmed one-click action: accept the handed-off case in place.
  accept,

  /// Open the case conversation.
  chat,
}

/// The button a queue card shows: its label, what it does, and whether it is
/// live. Pure data, mapped from the status alone — see [actionFor].
class QueueAction {
  const QueueAction({
    required this.label,
    required this.kind,
    required this.isEnabled,
  });

  final String label;
  final QueueActionKind kind;
  final bool isEnabled;
}

/// The action each status offers.
///
/// Everything routes to the case detail except [QueueStatus.assigned], the
/// confirmed one-click accept, and [QueueStatus.pendingInformation], which opens
/// the conversation. [QueueStatus.submitted] and [QueueStatus.closed] show their
/// button disabled: payment is not cleared on the first, and a closed case is
/// not re-assigned from here.
///
/// TODO(backend): the labels are the actions the real endpoints will drive.
QueueAction actionFor(QueueStatus status) => switch (status) {
  QueueStatus.paymentValidated => const QueueAction(
    label: 'Assign to staff',
    kind: QueueActionKind.detail,
    isEnabled: true,
  ),
  QueueStatus.submitted => const QueueAction(
    label: 'Assign to staff',
    kind: QueueActionKind.detail,
    isEnabled: false,
  ),
  QueueStatus.assigned => const QueueAction(
    label: 'Accept Assignment',
    kind: QueueActionKind.accept,
    isEnabled: true,
  ),
  QueueStatus.accepted => const QueueAction(
    label: 'Submit report',
    kind: QueueActionKind.detail,
    isEnabled: true,
  ),
  QueueStatus.underReview => const QueueAction(
    label: 'Start review',
    kind: QueueActionKind.detail,
    isEnabled: true,
  ),
  QueueStatus.pendingInformation => const QueueAction(
    label: 'Open chat',
    kind: QueueActionKind.chat,
    isEnabled: true,
  ),
  QueueStatus.closed => const QueueAction(
    label: 'Reassign to staff',
    kind: QueueActionKind.detail,
    isEnabled: false,
  ),
  QueueStatus.disputed => const QueueAction(
    label: 'Reassign to staff',
    kind: QueueActionKind.detail,
    isEnabled: true,
  ),
  QueueStatus.suspended => const QueueAction(
    label: 'Lift suspension',
    kind: QueueActionKind.detail,
    isEnabled: true,
  ),
};
