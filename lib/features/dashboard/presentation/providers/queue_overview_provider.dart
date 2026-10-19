import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The two counts above the staff queue: how much is waiting, how much shipped.
///
/// Mock for now.
///
/// TODO(backend): replace with the staff-overview endpoint.
final queueOverviewProvider = Provider<({int inQueue, int doneThisWeek})>((
  ref,
) {
  return (inQueue: 5, doneThisWeek: 2);
});
