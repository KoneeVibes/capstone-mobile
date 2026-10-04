# Tooling

## Toolchain

| Tool | Version | Notes |
| --- | --- | --- |
| Flutter | 3.38.x, stable channel | |
| Dart | 3.10.x | `environment.sdk: ^3.10.4` in `pubspec.yaml` |
| Android SDK + emulator | via Android Studio | |
| Xcode | for iOS builds | macOS only |

There is no code generation: no `build_runner`, no `freezed`, no
`riverpod_generator`. `flutter pub get` is the only setup step.

## Everyday commands

```sh
flutter pub get
flutter run                                   # debug, against the dev API
flutter run --dart-define=API_BASE_URL=https://staging.example.com
flutter analyze                               # must report no issues
flutter test
flutter build apk --debug                     # cheapest proof Android resources merge
```

### Compile-time defines

| Define | Default | Purpose |
| --- | --- | --- |
| `API_BASE_URL` | the development API | host only; `/api/v1` is appended |

## Formatting

Format **only the files you changed**:

```sh
dart format lib/features/auth/presentation/screens/login_screen.dart
```

Do not run `dart format lib test`. The tree is not formatter-clean against the
current SDK, and a full run rewrites dozens of untouched files — burying the real
change in a review, and once overwriting a colleague's uncommitted work.

## Lints

`analysis_options.yaml` extends `flutter_lints` with the project's conventions
(relative imports, single quotes, trailing commas, `unawaited_futures`, …).
`lib/shared/analysis_options.yaml` adds `public_member_api_docs` for the shared
code. See [Coding standards](standards.md).

## Launcher icons

[`flutter_launcher_icons`](https://pub.dev/packages/flutter_launcher_icons),
configured in `flutter_launcher_icons.yaml` (kept out of `pubspec.yaml` so it only
runs when asked).

```sh
dart run flutter_launcher_icons -f flutter_launcher_icons.yaml
```

Run it after replacing `assets/icons/app-icon.png`, then commit the generated
files under `android/app/src/main/res` and `ios/Runner/Assets.xcassets`. The
adaptive-icon background is `#FDFCFC` to match the opaque background baked into
the source art; a transparent-background source would allow pure white.

## Launch screens

Both native launch screens are pinned to white so the handoff to the Flutter
splash is invisible. On Android 12+ the system draws the launcher icon, not any
drawable, which is why the wordmark is drawn by Flutter. Do not add a
`values-night` resource folder: night beats version in Android's qualifier
precedence, and the template's black theme flashed on dark-mode devices.

## Driving the Android emulator from a shell

Useful for live verification and screenshots:

```sh
adb exec-out screencap -p > shot.png             # screenshot (avoids device paths)
adb shell input tap 720 1727                     # physical pixels
adb shell input text "'Secure123!'"              # quote so the device shell keeps "!"
adb shell am force-stop <package> && adb shell monkey -p <package> -c android.intent.category.LAUNCHER 1
```

- `keyevent 4` (Back) pops the route when no keyboard is showing — it does not
  only hide the keyboard. Submit with the field's Done action instead.
- Enter on an empty field does not move focus, so typed text lands one field
  early. Tap each field.
- A screenshot taken straight after a tap often shows the previous frame.
- On Windows, Git Bash rewrites `/sdcard/...` paths; use PowerShell for
  `adb push`.
- To photograph a loading state, point the app at an unreachable host
  (`--dart-define=API_BASE_URL=https://10.255.255.1`) so requests hang until the
  timeout.
