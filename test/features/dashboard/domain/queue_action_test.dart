import 'package:flutter_test/flutter_test.dart';
import 'package:propertyintelmobileapp/features/dashboard/domain/entities/queue_status.dart';
import 'package:propertyintelmobileapp/features/dashboard/domain/queue_action.dart';

void main() {
  test('every status maps to an action', () {
    for (final status in QueueStatus.values) {
      expect(actionFor(status).label, isNotEmpty);
    }
  });

  test('assigned is the one-click accept', () {
    final action = actionFor(QueueStatus.assigned);
    expect(action.kind, QueueActionKind.accept);
    expect(action.label, 'Accept Assignment');
    expect(action.isEnabled, isTrue);
  });

  test('pending information opens the chat', () {
    expect(
      actionFor(QueueStatus.pendingInformation).kind,
      QueueActionKind.chat,
    );
  });

  test('every other action opens the case detail', () {
    const detailStatuses = [
      QueueStatus.paymentValidated,
      QueueStatus.submitted,
      QueueStatus.accepted,
      QueueStatus.underReview,
      QueueStatus.closed,
      QueueStatus.disputed,
      QueueStatus.suspended,
    ];
    for (final status in detailStatuses) {
      expect(actionFor(status).kind, QueueActionKind.detail);
    }
  });

  test('submitted and closed are shown disabled', () {
    expect(actionFor(QueueStatus.submitted).isEnabled, isFalse);
    expect(actionFor(QueueStatus.closed).isEnabled, isFalse);
  });

  test('the live detail actions are enabled', () {
    expect(actionFor(QueueStatus.paymentValidated).isEnabled, isTrue);
    expect(actionFor(QueueStatus.underReview).isEnabled, isTrue);
    expect(actionFor(QueueStatus.disputed).isEnabled, isTrue);
    expect(actionFor(QueueStatus.suspended).isEnabled, isTrue);
  });
}
