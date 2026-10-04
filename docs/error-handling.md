# Error handling

The one rule that is not negotiable: **no raw exception ever reaches the UI.**
Why: [ADR 0002](adr/0002-result-and-error-handler.md).

## The contract

| Layer | Does | Never |
| --- | --- | --- |
| Datasource | throws (`DioException`, `FormatException`, …) | catches, except where a secondary read may fail quietly (documented in place) |
| Repository impl | catches everything at its boundary, converts with `ErrorHandler.from`, returns `Result<T>` | throws |
| Notifier | surfaces `AppFailure` (as `AsyncError`, or a returned `Result`) | stores a raw exception |
| Widget | renders `AppFailure.message` | calls `toString()` on an error, or shows `debugMessage` |

Nothing outside `ErrorHandler` calls `error.toString()`.

## `AppFailure`

```dart
AppFailure(
  type: FailureType.unauthorized,      // drives behaviour: retry, re-auth
  message: 'Incorrect password',       // the only thing a widget shows
  statusCode: 401,
  debugMessage: '...',                 // debug builds only, for logs
)
```

`failure.isRetryable` tells a screen whether a retry button makes sense.

## `ErrorHandler.from`

Converts anything thrown into an `AppFailure`:

- An `AppFailure` passes through unchanged, so double-wrapping is harmless.
- **HTTP errors take the server's message first**, when it reads like UI copy:
  short, one line, no stack traces or markup. The API's messages usually are
  ("Staff member not found.", "Incorrect password").
- Otherwise it falls back to wording inferred from the status code (401 →
  "Your session has expired…", 409 → "That already exists…").
- Timeouts, offline errors, cancellations and parse failures each get their own
  wording.

If an error needs mapping some other way, the mapping moves into `ErrorHandler`
— or into the one repository that owns that endpoint's quirk, documented there.

## Failures that are not exceptions: `AppFailures`

Conditions the app declares rather than catches live in `AppFailures`: an
unknown route, a denied photo picker, a file too large, an expired session, an
account type the app cannot route, a wrong one-time code. They are constants, so
tests compare them by equality.

## Reading errors in widgets

```dart
state.when2(
  loading: () => const CaseListSkeleton(),
  error: (failure) => AppStateView.failure(failure: failure, onRetry: refresh),
  data: (value) => ...,
);
```

`AsyncValueFailureX` (`when2`, `.failure`) normalises anything that slipped past
a repository through `ErrorHandler`, so even a bug cannot print exception text.
For one-off actions use `context.showFailure(failure)` — a snackbar that only
accepts an `AppFailure`.

## Endpoint quirks handled at the repository

Some endpoints say one thing with two status codes, or two things with one.
Those are translated in the repository that owns the endpoint, not in widgets:

- **A 404 from a list endpoint** means "none", not "broken" →
  `Ok([])` (cases, staff).
- **`verify-otp`** answers 400 "OTP not valid" for a wrong code and 409 "OTP not
  found" for an expired one → both become `AppFailures.invalidOtp`.
- **A 401 on a request that carried a token** ends the session (handled in the
  API client's interceptor, see [Navigation and auth](navigation-and-auth.md)).

## Logging

Diagnostics go to the debug log through the networking layer's interceptor,
never to the screen. Secrets are masked before they are printed — see
[Networking](networking.md#logging). There is no crash reporter yet.
