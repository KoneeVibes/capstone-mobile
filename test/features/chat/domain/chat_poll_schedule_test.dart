import 'package:flutter_test/flutter_test.dart';
import 'package:propertyintelmobileapp/features/chat/domain/chat_poll_schedule.dart';

void main() {
  Duration seconds(int value) => Duration(seconds: value);

  test('slows from 4s to 30s as reads keep bringing nothing new', () {
    var schedule = const ChatPollSchedule();
    final delays = <Duration>[];
    for (var i = 0; i < 12; i++) {
      delays.add(schedule.delay(isOpen: true));
      schedule = schedule.afterQuietPoll();
    }

    expect(delays, [
      for (final step in [4, 8, 15, 30]) ...List.filled(3, seconds(step)),
    ]);
    // And stays there.
    expect(schedule.delay(isOpen: true), seconds(30));
  });

  test('any activity starts fast again', () {
    var schedule = const ChatPollSchedule();
    for (var i = 0; i < 20; i++) {
      schedule = schedule.afterQuietPoll();
    }

    expect(schedule.afterActivity().delay(isOpen: true), seconds(4));
  });

  test('a closed conversation is checked every 30s, however active', () {
    expect(const ChatPollSchedule().delay(isOpen: false), seconds(30));
  });

  test('failures double the wait up to a minute; a good read clears them', () {
    var schedule = const ChatPollSchedule().afterFailure();
    expect(schedule.delay(isOpen: true), seconds(8));

    schedule = schedule.afterFailure();
    expect(schedule.delay(isOpen: true), seconds(16));

    for (var i = 0; i < 40; i++) {
      schedule = schedule.afterFailure();
    }
    expect(schedule.delay(isOpen: true), seconds(60));
    expect(schedule.delay(isOpen: false), seconds(60));

    expect(schedule.afterQuietPoll().failures, 0);
    expect(schedule.afterActivity().delay(isOpen: true), seconds(4));
  });
}
