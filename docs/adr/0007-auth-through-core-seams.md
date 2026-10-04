# 0007 — Auth plugs into core through provider seams

- **Status:** Accepted
- **Recorded:** 2026-10-04

## Context

Almost everything depends on who is signed in: the router, the API client (the
bearer token, and what a 401 means), the Cases screens (staff-only actions) and
every list holding one user's data. But features may not import each other, and
`core/` may not import a feature. Moving the session into the auth feature would
force every other feature to import auth.

## Decision

Core declares small providers with **signed-out defaults**:

- `sessionProvider` — `SessionUser?`
- `hasSeenOnboardingProvider` — `bool`
- `sessionRestoreProvider` — completes when the stored session has been read
- `authTokenProvider` — supplies the bearer token
- `unauthorizedHandlerProvider` — called on a 401 for an authenticated request

The auth feature exports `authOverrides`, which `main.dart` passes to the
`ProviderScope`. Nothing else imports auth.

The token supplier and the 401 handler read the session lazily, inside their
callbacks. Watching it would rebuild Dio on every sign-in, and would form a
cycle — the session's repository itself uses Dio.

## Consequences

- Features and the router depend only on core; auth can change internally
  without touching them.
- Tests run any feature signed in or out by overriding `sessionProvider`
  directly, and test auth itself by including `authOverrides`.
- Forgetting the overrides gives a permanently signed-out app — visible at once,
  not a silent bug.
- Every provider holding one user's data must `ref.watch(sessionProvider)` in
  `build` so the next user starts from nothing. That is a convention, not
  something the compiler checks.
