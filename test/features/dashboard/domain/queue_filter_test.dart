import 'package:flutter_test/flutter_test.dart';
import 'package:propertyintelmobileapp/features/dashboard/domain/entities/queue_filter.dart';
import 'package:propertyintelmobileapp/features/dashboard/domain/entities/queue_status.dart';

void main() {
  test('All admits every status', () {
    for (final status in QueueStatus.values) {
      expect(QueueFilter.all.matches(status), isTrue);
    }
  });

  test('New is the work waiting to be picked up', () {
    expect(QueueFilter.fresh.matches(QueueStatus.paymentValidated), isTrue);
    expect(QueueFilter.fresh.matches(QueueStatus.submitted), isTrue);
    expect(QueueFilter.fresh.matches(QueueStatus.assigned), isFalse);
  });

  test('Assigned is the work in hand', () {
    for (final status in [
      QueueStatus.assigned,
      QueueStatus.accepted,
      QueueStatus.underReview,
      QueueStatus.pendingInformation,
    ]) {
      expect(QueueFilter.assigned.matches(status), isTrue);
    }
    expect(QueueFilter.assigned.matches(QueueStatus.closed), isFalse);
  });

  test('Closed is the finished and halted work, disputes included', () {
    for (final status in [
      QueueStatus.closed,
      QueueStatus.suspended,
      QueueStatus.disputed,
    ]) {
      expect(QueueFilter.closed.matches(status), isTrue);
    }
    expect(QueueFilter.closed.matches(QueueStatus.accepted), isFalse);
  });

  test('the narrow tabs partition every status exactly once', () {
    final narrow = [
      QueueFilter.fresh,
      QueueFilter.assigned,
      QueueFilter.closed,
    ];
    for (final status in QueueStatus.values) {
      final hits = narrow.where((filter) => filter.matches(status)).length;
      expect(hits, 1, reason: '$status should sit under exactly one tab');
    }
  });
}
