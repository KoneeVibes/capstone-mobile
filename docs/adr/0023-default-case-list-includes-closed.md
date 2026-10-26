# 0023 — The default case list includes closed cases

- **Status:** Accepted
- **Recorded:** 2026-10-26

## Context

ADR 0006 fetched closed cases in a second `filter=closed` request and merged
them by id, because the spec documents the unfiltered `GET /case` as "all
active case statuses". The tracking lookup and the client home counts did the
same.

Since the backend's 26 Oct visibility fix, the unfiltered list carries closed
cases too. Checked live, read-only, on 26 Oct 2026 as super-admin, manager,
regular and client: every case `filter=closed` returned was already in the
unfiltered list.

## Decision

- **One unfiltered request.** The cases list, the client home counts and the
  tracking address lookup each read `GET /case` (all pages) and nothing else.
  The `filter=closed` request and the merge are gone.
- ADR 0006's other decisions stand: no status is named in `filter`, every
  page is walked, and tabs filter on the device.

## Consequences

- One request fewer per list load, per home load and per tracking lookup.
- If the backend ever drops closed cases from the default again, the Closed
  tab goes quietly empty. The unit tests pin the single request; a live
  check of the Closed tab catches it.
