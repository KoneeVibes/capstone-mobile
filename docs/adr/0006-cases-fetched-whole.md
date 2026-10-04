# 0006 — Fetch the case list whole and filter on the device

- **Status:** Accepted
- **Recorded:** 2026-10-04 (decided 2026-08-31)

## Context

The cases screen has a tab per status — nine with "All" — and a footer like
"2 of 5 cases", which needs both the filtered count and the total. One page from
the server cannot answer both. Server-side filtering also proved unreliable: the
endpoint silently ignores a `filter` value it does not recognise and answers
with everything, and a filter that matches nothing returns a 404 whose envelope
says `success`.

## Decision

- Request every case, walking `meta.totalPages` with `perPage=100`
  (`ApiClient.getAllPages`), and filter by tab on the device.
- Name no status in the main request. Closed cases are fetched in one extra
  `filter=closed` request and merged by id, because the default is documented as
  "all active". A 404 there means none; any other failure propagates.

## Consequences

- Switching tabs is instant and costs no request; the footer is always right.
- Every case is held in memory. That is fine at current volumes; moving to
  server-side paging means a datasource change, paging state in the notifier, and
  rethinking the footer — do it when volume, not principle, demands it.
- A status the backend adds later still arrives and shows under "All".
