# 0001 — Riverpod 3 without code generation

- **Status:** Accepted
- **Recorded:** 2026-10-04 (decided at project start)

## Context

The app needs state management that is testable without widgets, supports
async loading with error states, and doubles as dependency injection. The team
also wanted a project with no generated files to regenerate, review or keep in
sync.

## Decision

Use `flutter_riverpod` 3 with hand-written providers: `Provider` and
`FutureProvider` for wiring and simple reads, `Notifier` and `AsyncNotifier`
(including `.family`) for anything with behaviour. No `riverpod_generator`, no
`build_runner`, no `freezed`.

## Consequences

- Providers are plain Dart; setup is `flutter pub get`, with no generation step
  to forget.
- Riverpod's providers are the DI container too ([0009](0009-platform-plugins-behind-wrappers.md),
  [Dependency injection](../dependency-injection.md)).
- Some Riverpod docs assume codegen. Family notifiers take their argument
  through the constructor, not `build`; this has to be learned once.
- Riverpod 3 retries a `build` that throws. Lookups that can legitimately fail
  set `AsyncError` from a method instead of throwing from `build`.
- Equality on state classes is written by hand with `equatable`.
