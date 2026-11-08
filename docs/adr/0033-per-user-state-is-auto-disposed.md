# 0033 — Per-user state is auto-disposed

- **Status:** Accepted
- **Recorded:** 2026-11-08

## Context

Providers that hold one user's data watch `sessionProvider`, so a sign-out or
a different sign-in rebuilds them. Most of them were app-wide singletons that
lived for the whole run.

In Riverpod 3, a rebuild caused by `ref.watch` carries the previous value
forward (`copyWithPrevious`): into `AsyncLoading` while the new load runs, and
into `AsyncError` if it fails. Assigning `state` inside `build` goes through the
same merge. Screens show `value` first, so after one account signed out and
another signed in, the new user saw the last one's cases, counts, staff list,
tracked case or profile. That lasted until their own data arrived, or for
good if their first load failed. Long-lived providers that never watched the
session were worse: the assignee list never reloaded at all.

## Decision

- **Every provider of one user's data is `autoDispose`.** These are the cases
  list, the staff list, both home overviews, recent searches, tracking, the
  case assignees, profile, notifications (with its repository and unread dot),
  and the `signedInFirstNameProvider` seam. Case detail, disputes, both
  searches, the invoice and the search form already were.
- **Sign-out is what disposes them.** It unmounts the signed-in shells and the
  full-screen routes, so nothing listens any more and the state is dropped.
  The next user starts from nothing. While signed in, the indexed-stack shell
  keeps every tab mounted, so nothing is re-fetched by switching tabs.
- **They keep watching the session.** That stops them fetching while signed
  out, which disposal alone would not.
- **Rules that follow:**
  - Per-user state must not be watched from above the signed-in screens, or by
    a provider that is not `autoDispose`.
  - A write that updates another screen's provider checks `ref.exists` first,
    as the case writes already did.
  - A notifier checks `ref.mounted` after every `await` before setting state.
- **Regression tests** in the profile and overview provider tests sign one user
  out and another in, then assert that no previous value shows, including
  after a failed load. The profile test fails without `autoDispose`.

## Consequences

- Leaving the staff tracking lookup, which is a pushed route, now clears its
  last result. The client's Search tab is a shell root, so it keeps its result.
- The assignee list is fetched each time the assign sheet opens, not once per
  run.
- Chat is left as it is. Its in-memory mock is shared across roles on purpose
  (ADR 0016), and it goes away with the mock.
- `valueFor`, the profile-only id check added earlier on this branch, is gone:
  disposal covers every per-user provider at once.
