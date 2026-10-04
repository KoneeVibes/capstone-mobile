# Testing

## What we test

**Unit tests only — no widget or golden tests** ([ADR 0010](adr/0010-unit-tests-only.md)).
That covers:

- **Models** — decoding real and odd payloads, request bodies.
- **Datasources** — the right endpoint, query and body; how responses decode;
  which failures propagate and which are swallowed.
- **Repositories** — exception → `Result` conversion, and each endpoint quirk
  they translate.
- **Notifiers** — state after load, mutation, failure; user switches.
- **Core** — the redirect rules, formatters, validators, `ErrorHandler`, the
  API client's envelope, logging redaction and 401 handling.

## Layout

`test/` mirrors `lib/`: the test for
`lib/features/auth/data/repositories/auth_repository_impl.dart` is
`test/features/auth/data/repositories/auth_repository_impl_test.dart`. Shared
fixtures sit at the feature root (`test/features/cases/case_fixtures.dart`).

## Tools

- [`mocktail`](https://pub.dev/packages/mocktail) for mocks — no codegen. Mock the
  layer directly beneath the one under test.
- `ProviderContainer` with overrides for notifiers
  ([Dependency injection](dependency-injection.md#testing-with-overrides)).
- [`fake_async`](https://pub.dev/packages/fake_async) for timers. Code that reads
  the time uses `clock.now()` from `package:clock`, which `fakeAsync` controls;
  `DateTime.now()` would not move. Repositories that need the time take a clock
  function instead (`AuthRepositoryImpl(clock: …)`).
- **Never hit the live network.** For code that must exercise the real Dio
  interceptors, swap in a fake `HttpClientAdapter` (see `api_client_test.dart`).

## Running

```sh
flutter test                      # everything
flutter test test/features/auth   # one feature
flutter analyze                   # must be clean too
```

## Habits that have paid off

- **Name the test after the behaviour**, not the method:
  `'a 409 reads as a wrong code'`.
- **Pin the live samples.** When the API surprises you, put the real response in
  a fixture and a test with a comment saying when it was seen
  (`liveClientToken` in `auth_fixtures.dart`).
- **Do not await `provider.future` when `build` may throw** — it never completes.
  Listen to the provider and assert on the state.

## Verify against the live API

Unit tests check the envelope **you believe** the API returns; mocks encode that
belief. Every feature with writes has had a bug that only a live run found — a
create that succeeded but reported failure, a wrong-code status nobody
documented, a token in the log. So, before calling a feature done:

1. Run the app (debug build) against the development API.
2. Exercise every write through the real UI, so the whole chain runs.
3. Read the debug log for each request: status, body, and that no secret is in
   clear.
4. Note up front what cannot be cleaned up afterwards — soft deletes leave
   inactive rows, and sign-ups leave accounts.

Use throwaway accounts on a public inbox service for flows that email codes, and
keep their credentials out of the repository.
