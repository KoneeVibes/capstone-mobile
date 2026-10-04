# 0002 — Repositories return `Result`; one `ErrorHandler`

- **Status:** Accepted
- **Recorded:** 2026-10-04 (decided at project start)

## Context

Raw exception text — `DioException [bad response]: …`, stack traces, HTML error
pages — is unreadable to users and can leak internals. When every layer catches
and words errors its own way, the same failure reads differently on every
screen, and sooner or later one screen prints `error.toString()`.

## Decision

- Datasources throw. Repository implementations are the **only** place that
  catches; they convert through `ErrorHandler.from` and return a sealed
  `Result<T>` — `Ok(value)` or `Err(AppFailure)`.
- `ErrorHandler` is the only code allowed to inspect a raw exception. It prefers
  a presentable server `message`, and falls back to wording inferred from the
  status code.
- Conditions that are not exceptions are declared as constants in `AppFailures`.
- Widgets render `AppFailure.message` and nothing else. `AsyncValueFailureX`
  normalises anything that slips through.

## Consequences

- Callers cannot forget the failure path; `Result` must be unwrapped or folded.
- User-facing wording is consistent and lives in two files.
- The API's own messages are usually good, so they win by default. When a
  design asks for different wording ("Tracking ID not found" vs the server's
  "Case not found."), the change belongs in `ErrorHandler`, `AppFailures` or the
  backend, not in a widget.
- An endpoint whose status codes mean something unusual — a 404 meaning "none",
  a 400 meaning "wrong code" — is translated in its own repository and
  documented there.
