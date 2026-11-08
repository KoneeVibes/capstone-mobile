# State management

[Riverpod 3](https://riverpod.dev) (`flutter_riverpod`), **without code
generation**. Class-based `Notifier` / `AsyncNotifier` for anything with
behaviour; plain `Provider` / `FutureProvider` for wiring and simple reads.
Why: [ADR 0001](adr/0001-riverpod-without-codegen.md).

## Which provider to use

| You need | Use | Example |
| --- | --- | --- |
| A dependency (client, repository) | `Provider` | `casesRepositoryProvider` |
| A read with no later writes | `FutureProvider` | `caseAssigneesProvider`, `recentSearchesProvider` |
| Data that loads, then changes | `AsyncNotifierProvider` | `casesListProvider` |
| The same, one per argument | `AsyncNotifierProvider.family` | `caseDetailProvider(id)` |
| Synchronous in-memory state | `NotifierProvider` | `signUpFlowProvider` |
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

### One user's data watches the session and is auto-disposed

Providers are app-wide singletons, so a list loaded for one user would still be
there for the next. Every provider holding one user's data does two things:

```dart
final casesListProvider = AsyncNotifierProvider.autoDispose<...>(...);

// in build:
if (ref.watch(sessionProvider) == null) return untilSignedIn();
```

Watching the session stops it fetching while signed out. **That alone is not
enough**: a rebuild caused by a watched dependency keeps the previous value, in
loading *and* in error, so the next user would see the last one's data until
theirs arrived, or for good if their first load failed. `autoDispose` is what
clears it. Sign-out unmounts the signed-in screens, nothing listens, and the
state is thrown away ([ADR 0033](adr/0033-per-user-state-is-auto-disposed.md)).

So: no app-level widget or non-auto-dispose provider may watch per-user state
(a seam over it, like `signedInFirstNameProvider`, is auto-dispose too). Any
write that touches another screen's per-user provider checks `ref.exists`
first, and a notifier checks `ref.mounted` after every `await`.

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
  storage) and the onboarding flag (preferences). In-progress sign-up or reset
  flows are memory-only by decision; recent searches live on the server
  (ADR 0029).
