import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/navigation/app_session.dart';
import '../../../../core/session/cases_changed.dart';
import '../../../../core/utils/error/failure_type.dart';
import '../../../../core/utils/result.dart';
import '../../domain/chat_poll_schedule.dart';
import '../../domain/entities/chat_conversation.dart';
import '../../domain/entities/chat_message.dart';
import 'chat_providers.dart';

/// One case conversation, keyed by case id, kept fresh by re-reading the case
/// while its screen is up (ADR 0036).
///
/// Each read arms a one-shot timer for the next, so reads never overlap and a
/// slow network slows the polling with it. Leaving the screen disposes this
/// and the timer; [pause] stops it while the app is hidden.
class ChatNotifier extends AsyncNotifier<ChatConversation> {
  ChatNotifier(this.caseId);

  final String caseId;

  Timer? _timer;
  ChatPollSchedule _schedule = const ChatPollSchedule();
  bool _paused = false;

  /// Bumped whenever a read in flight should no longer count: a send or a
  /// toggle has made it stale, or the app was hidden.
  int _generation = 0;

  @override
  Future<ChatConversation> build() async {
    final viewer = ref.watch(sessionProvider);
    if (viewer == null) return untilSignedIn();

    _schedule = const ChatPollSchedule();
    ref.onDispose(_stopPolling);

    final result = await ref.read(chatRepositoryProvider).fetchThread(caseId);
    final thread = result.unwrapOrThrow();
    _arm(isOpen: thread.isOpen);
    return ChatConversation(
      thread: thread,
      viewerId: viewer.id,
      viewerIsStaff: viewer.isStaff,
    );
  }

  /// Shows [text] at once, then swaps in the server's copy. A failure takes
  /// it back out, for the screen to hand the text back to the composer.
  Future<Result<void>> send(String text) async {
    final trimmed = text.trim();
    final current = state.value;
    if (current == null ||
        !current.canType ||
        current.isSending ||
        trimmed.isEmpty) {
      return const Ok(null);
    }

    final repository = ref.read(chatRepositoryProvider);
    _stopPolling();
    state = AsyncData(
      current.withPending(
        ChatMessage(
          id: 'pending',
          senderId: current.viewerId,
          text: trimmed,
          sentAt: clock.now(),
          isPending: true,
        ),
      ),
    );

    final result = await repository.sendMessage(caseId, trimmed);
    if (!ref.mounted) return result;

    _schedule = _schedule.afterActivity();
    final latest = state.requireValue;
    switch (result) {
      case Ok(:final value):
        state = AsyncData(latest.withSent(value));
        _arm(isOpen: true);
      case Err(:final failure):
        state = AsyncData(latest.withoutPending());
        // A conflict means it was closed meanwhile: show that now.
        if (failure.type == FailureType.conflict) {
          unawaited(_poll());
        } else {
          _arm(isOpen: latest.thread.isOpen);
        }
    }
    return result;
  }

  /// Opens or closes the conversation, then re-reads it. The case's status
  /// moves too, so the case screens are told.
  Future<Result<void>> toggle() async {
    final current = state.value;
    if (current == null || !(current.canOpen || current.canClose)) {
      return const Ok(null);
    }

    final repository = ref.read(chatRepositoryProvider);
    final casesChanged = ref.read(casesChangedProvider.notifier);
    _stopPolling();

    final result = await repository.toggleConversation(caseId);
    if (result.isOk) casesChanged.bump();
    if (!ref.mounted) return result;

    // Re-read either way: a refusal usually means it changed under us.
    _schedule = _schedule.afterActivity();
    await _poll();
    return result;
  }

  /// The app went out of view: nothing is fetched until [resume].
  void pause() {
    _paused = true;
    _stopPolling();
  }

  /// Back in view: catch up at once, then poll quickly again.
  void resume() {
    if (!_paused) return;
    _paused = false;
    _schedule = _schedule.afterActivity();
    if (state.hasValue) unawaited(_poll());
  }

  Future<void> _poll() async {
    _timer?.cancel();
    final generation = ++_generation;
    final result = await ref.read(chatRepositoryProvider).fetchThread(caseId);
    if (!ref.mounted || generation != _generation) return;

    final current = state.value;
    if (current == null) return;
    switch (result) {
      case Ok(:final value) when value == current.thread:
        _schedule = _schedule.afterQuietPoll();
      case Ok(:final value):
        _schedule = _schedule.afterActivity();
        state = AsyncData(current.withThread(value));
      // The transcript stays up; the next try waits longer.
      case Err():
        _schedule = _schedule.afterFailure();
    }
    _arm(isOpen: state.requireValue.thread.isOpen);
  }

  void _arm({required bool isOpen}) {
    _timer?.cancel();
    if (_paused) return;
    _timer = Timer(_schedule.delay(isOpen: isOpen), _poll);
  }

  void _stopPolling() {
    _generation++;
    _timer?.cancel();
  }
}

/// Dropped with the chat screen, which stops the polling and lets the next
/// user start from nothing.
final chatProvider = AsyncNotifierProvider.autoDispose
    .family<ChatNotifier, ChatConversation, String>(ChatNotifier.new);
