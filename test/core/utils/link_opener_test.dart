import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:propertyintelmobileapp/core/utils/error/app_failures.dart';
import 'package:propertyintelmobileapp/core/utils/link_opener.dart';

class MockLinkLauncherBackend extends Mock implements LinkLauncherBackend {}

const _pdf = 'https://res.cloudinary.com/demo/image/upload/survey/plan.pdf';

void main() {
  setUpAll(() => registerFallbackValue(Uri.parse('https://example.com')));

  late MockLinkLauncherBackend backend;
  late LinkOpener opener;

  setUp(() {
    backend = MockLinkLauncherBackend();
    opener = LinkOpener(backend);
  });

  test('opens a document link and reports success', () async {
    when(() => backend.launch(any())).thenAnswer((_) async => true);

    final result = await opener.open(_pdf);

    expect(result.isOk, isTrue);
    verify(() => backend.launch(Uri.parse(_pdf))).called(1);
  });

  test('trims surrounding whitespace before parsing', () async {
    when(() => backend.launch(any())).thenAnswer((_) async => true);

    await opener.open('  $_pdf  ');

    verify(() => backend.launch(Uri.parse(_pdf))).called(1);
  });

  test('fails when nothing on the device would open it', () async {
    when(() => backend.launch(any())).thenAnswer((_) async => false);

    final result = await opener.open(_pdf);

    expect(result.isErr, isTrue);
    expect(result.failureOrNull, AppFailures.linkNotOpenable);
  });

  test('converts a plugin exception rather than letting it escape', () async {
    // Nothing above this may see a PlatformException — the whole point of
    // routing url_launcher through here.
    when(
      () => backend.launch(any()),
    ).thenThrow(PlatformException(code: 'ACTIVITY_NOT_FOUND'));

    final result = await opener.open(_pdf);

    expect(result.failureOrNull, AppFailures.linkNotOpenable);
  });

  group('rejects a URL it cannot use, without calling the plugin', () {
    for (final url in const ['', '   ', 'not a url', '/relative/path.pdf']) {
      test('"$url"', () async {
        final result = await opener.open(url);

        expect(result.isErr, isTrue);
        expect(result.failureOrNull, AppFailures.linkNotOpenable);
        verifyNever(() => backend.launch(any()));
      });
    }
  });

  test('both causes read as one failure', () async {
    // A broken URL and a device with no viewer are indistinguishable to the
    // user and there is nothing different to do about either, so they share a
    // message. The copy tells them to try again or use the web app, which is
    // the same advice in both cases.
    when(() => backend.launch(any())).thenAnswer((_) async => false);

    final noViewer = await opener.open(_pdf);
    final malformed = await opener.open('not a url');

    expect(noViewer.failureOrNull, malformed.failureOrNull);
  });
}
