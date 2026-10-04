# Property Intel — mobile

The Flutter app for Capstone PropertyIntel: check that a property is free of
known litigation and disputes before paying for it. One app serves two
audiences:

- **Clients** sign up, request property searches and track their cases.
- **Staff** look up cases by tracking ID, assign them to team members, and
  manage staff accounts.

## Requirements

- Flutter **3.38** (stable channel) with Dart **3.10**
- Android Studio with an Android SDK and an emulator, or a device
- Xcode, for iOS builds (macOS only)

No code generation, no environment files, no keys to install.

## Run it

```sh
flutter pub get && flutter run
```

That runs a debug build against the shared development API. To point at another
environment:

```sh
flutter run --dart-define=API_BASE_URL=https://staging.example.com
```

The first request after the API has been idle can take around 20 seconds — it
is hosted on a tier that sleeps. That is expected, not a hang.

To sign in you need an account: clients can register in the app; staff accounts
are created by an admin.

## Checks

```sh
flutter analyze   # must report no issues
flutter test      # unit tests; never touch the network
```

## How it is built

**Clean Architecture, one feature at a time.** Each feature under
`lib/features/` has `data/`, `domain/` and `presentation/` layers, and features
never import each other. Shared code lives in `lib/core/` (non-visual) and
`lib/shared/` (widgets). → [Architecture](docs/architecture.md)

**State management: Riverpod 3, without code generation.** Riverpod gives
testable async state *and* dependency injection in one tool, and hand-written
providers mean no generated files to keep in sync.
→ [State management](docs/state-management.md) ·
[ADR 0001](docs/adr/0001-riverpod-without-codegen.md)

**Errors never reach the UI raw.** Repositories return `Result<T>`, one
`ErrorHandler` words every failure, and widgets render only
`AppFailure.message`. → [Error handling](docs/error-handling.md)

**Navigation: go_router**, with one tab shell per role and a single, unit-tested
redirect rule. → [Navigation and auth](docs/navigation-and-auth.md)

Main dependencies: `flutter_riverpod`, `go_router`, `dio`, `equatable`, `intl`,
`flutter_secure_storage`, `shared_preferences`, `image_picker`, `file_picker`,
`url_launcher`, `shimmer`. Tests use `mocktail` and `fake_async`.

## Debugging

- **Network log.** Debug builds print every request and response — method, URL,
  headers, payload, status and body — to the console (`flutter run` output or
  logcat). Tokens and password fields are masked. Release builds log nothing.
  → [Networking](docs/networking.md#logging)
- **Riverpod and router state.** go_router's diagnostics are on in debug builds.
  Use Flutter DevTools for widget and provider inspection.
- **Crash reporting and session replay** are not set up yet.

## Localisation

None yet: the app is English-only, and screen text lives on the screen that
renders it. Dates and money are formatted through `AppFormatters` with `intl`, so
a later move to `flutter gen-l10n` starts from one formatting layer.

## Tools

| Tool | Why | How |
| --- | --- | --- |
| `flutter_launcher_icons` | generates launcher icons from `assets/icons/app-icon.png` | `dart run flutter_launcher_icons -f flutter_launcher_icons.yaml` |
| `--dart-define` | selects the API host at build time | `API_BASE_URL=…` |

→ [Tooling](docs/tooling.md), including how to drive the emulator from a shell.

## Documentation

Everything else is in [`docs/`](docs/README.md): dependency injection, UI and
design system, accessibility, testing (including checking against the live API),
coding standards, and the [architecture decision records](docs/adr/README.md).
