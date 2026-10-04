# 0010 — Unit tests only, plus a live check

- **Status:** Accepted
- **Recorded:** 2026-10-04

## Context

Widget and golden tests are slow to write and brittle while designs are still
moving, and golden images differ across platforms. Most of the app's risk is in
data handling — envelopes, error mapping, state transitions, routing rules —
which unit tests cover cheaply. But mocks encode what we *believe* the API does,
and the API has repeatedly done something else.

## Decision

- **Unit tests only**: models, datasources, repositories, notifiers and core
  logic, with `mocktail` and `ProviderContainer`. No widget or golden tests.
- **No test touches the live network.**
- **Every feature with writes is also exercised against the live development API**
  through the real UI before it is called done, reading the debug log for each
  request.

## Consequences

- The suite runs in seconds and stays stable through visual changes.
- Layout regressions are caught by eye, on a device, not by CI.
- Live checks have caught what unit tests structurally could not: a create that
  succeeded but reported failure (no `data` node), an undocumented 400 for a
  wrong code, and secrets in the debug log. They also leave data behind — test
  accounts and soft-deleted rows — which must be noted.
- Logic that matters is pulled out of widgets into functions and notifiers
  (`redirectFor`, flow notifiers) precisely so it can be unit-tested.
