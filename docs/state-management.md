# State management

[Riverpod 3](https://riverpod.dev) (`flutter_riverpod`), **without code
generation**. Class-based `Notifier` / `AsyncNotifier` for anything with
behaviour; plain `Provider` / `FutureProvider` for wiring and simple reads.
Why: [ADR 0001](adr/0001-riverpod-without-codegen.md).

## Which provider to use

| You need | Use | Example |
| --- | --- | --- |
| A dependency (client, repository) | `Provider` | `casesRepositoryProvider` |
| A read with no later writes | `FutureProvider` | `caseAssigneesProvider` |
| Data that loads, then changes | `AsyncNotifierProvider` | `casesListProvider` |
| The same, one per argument | `AsyncNotifierProvider.family` | `caseDetailProvider(id)` |
| Synchronous in-memory state | `NotifierProvider` | `recentSearchesProvider`, `signUpFlowProvider` |
| A one-shot write with a loading state | `AsyncNotifier<void>` | `staffMutationProvider` |

## Patterns

### Load in `build`, surface failures as `AsyncError`

```dart
@override
Future<CasesListState> build() async {
  ref.watch(sessionProvider);
  final result = await ref.read(casesRepositoryProvider).fetchCases();
  return CasesListState(items: result.unwrapOrThrow());
}
```

`unwrapOrThrow` throws the `AppFailure`; Riverpod stores it as `AsyncError`, and
widgets read it back through `AsyncValueFailureX` (`state.when2(...)` or
`state.failure`).

### Lookups that can fail set the error instead of throwing it

Riverpod 3 **retries a provider whose `build` throws**, with backoff. Right for
a list that hiccupped; wrong for a lookup that 404s, or a request that 401s.
`TrackingNotifier` builds to `null` and sets `state = AsyncError(...)` from its
`track()` method, so nothing is retried behind the user's back.
`AuthSessionNotifier.build` never throws for the same reason.

### Mutations return whether they worked

```dart
Future<bool> createStaff(StaffDraft draft) => _run(() => repo.createStaff(draft));
```

The calling sheet decides to close or stay open. On failure the notifier holds
`AsyncError(failure)` for the widget to show. Auth flows return the `Result`
itself, because the screen branches on which failure it was.

### Push a write's response into state; do not re-fetch

When a write returns the updated record, put it straight into the list and
detail notifiers (`replaceCase`, `replaceWith`). Re-fetching leaves the screen
contradicting its own confirmation for a round trip — about 23 seconds on a cold
start of the hosting. Invalidate only when there is no record to put back.

### One user's data watches the session

Providers are app-wide singletons, so a list loaded for one user would still be
there for the next. Every provider holding one user's data watches the session
in `build`:

```dart
ref.watch(sessionProvider); // a new user starts from nothing
```

A sign-out or a different sign-in rebuilds it. Today that covers the cases
list and detail, the staff list, tracking and recent searches. New
user-scoped providers must do the same.

### Family notifiers take their argument through the constructor

Without codegen, a family `AsyncNotifier` gets its argument from the
constructor and has a no-argument `build`:

```dart
class CaseDetailNotifier extends AsyncNotifier<Case> {
  CaseDetailNotifier(this.caseId);
  final String caseId;
  @override
  Future<Case> build() async { ... }
}

final caseDetailProvider =
    AsyncNotifierProvider.family<CaseDetailNotifier, Case, String>(
      CaseDetailNotifier.new,
    );
```

The codegen docs show `build(String id)`; that does not compile here.

## Pitfalls (each of these has cost time)

- `AsyncValue.value`, not `valueOrNull` — that was Riverpod 2.
- `AsyncNotifier` already defines `update()`. Name mutations `updateStaff`,
  `removeStaff`, and so on.
- `provider.future` never completes when `build` throws. A test awaiting it
  hangs until the timeout; listen to the provider and assert on the state.
- `Override` is exported from `package:flutter_riverpod/misc.dart`.
- `ref.read` in `build` does not rebuild on change; `ref.watch` does. Read
  repositories (they never change), watch the session.

## Where state does not go

- **Not in widgets**, beyond ephemeral UI state — text controllers, a
  `_busy` flag for one submit, an obscured-password toggle.
- **Not in `core/`** — except the session seams, which are declarations
  supplied by auth ([Architecture](architecture.md#where-cross-feature-state-lives)).
- **Not on disk**, unless it must outlive a restart: the session token (secure
  storage) and the onboarding flag (preferences). Recent searches and in-progress
  sign-up or reset flows are memory-only by decision.
