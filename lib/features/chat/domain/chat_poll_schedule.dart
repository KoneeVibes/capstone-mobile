import 'dart:math' as math;

import '../../../core/constants/app_constants.dart';

/// How long to wait before the next re-read of a conversation.
///
/// There is no socket, so the screen polls (ADR 0036): quickly while messages
/// are moving, slower the longer nothing changes, slower still after failures.
class ChatPollSchedule {
  const ChatPollSchedule({this.quietPolls = 0, this.failures = 0});

  /// Reads in a row that brought nothing new.
  final int quietPolls;

  /// Reads in a row that failed.
  final int failures;

  /// A message came or went, or the reader came back: start fast again.
  ChatPollSchedule afterActivity() => const ChatPollSchedule();

  ChatPollSchedule afterQuietPoll() =>
      ChatPollSchedule(quietPolls: quietPolls + 1);

  ChatPollSchedule afterFailure() =>
      ChatPollSchedule(quietPolls: quietPolls, failures: failures + 1);

  /// A closed conversation is only watched for being opened.
  Duration delay({required bool isOpen}) {
    final healthy = isOpen ? _openDelay : AppConstants.chatPollClosedInterval;
    if (failures == 0) return healthy;
    // Doubling per failure; the shift is capped so it cannot overflow.
    final backedOff = healthy * (1 << math.min(failures, 8));
    return backedOff < AppConstants.chatPollMaxBackoff
        ? backedOff
        : AppConstants.chatPollMaxBackoff;
  }

  Duration get _openDelay {
    const steps = AppConstants.chatPollSteps;
    final step = quietPolls ~/ AppConstants.chatPollsPerStep;
    return steps[math.min(step, steps.length - 1)];
  }
}
