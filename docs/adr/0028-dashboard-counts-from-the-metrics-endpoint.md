# 0028 — Home counts come from the metrics endpoint

- **Status:** Accepted
- **Recorded:** 2026-11-02

## Context

The client Home's four cards were counted on the device. The app walked every
page of `GET /case` and sorted the statuses itself. The staff home's two cards
were a hard-coded mock showing 5 / 2 (ADRs 0016, 0019). The backend now serves
both from `GET /dashboard/metrics`, and the token decides which shape comes
back:

- **Clients** (registered and guest) get `{totalSearches, reportsReady,
  inProgress, needsYourInput}`, counted over cases whose applicant email
  matches theirs.
- **Staff** get `{queue, recent}` and `meta {recentSince, asOf}`.
  - `queue` counts the cases assigned to the member. A super-admin's `queue`
    also counts every case under review.
  - `recent` counts the cases assigned to the member in the last seven days.

## Decision

- **Both homes read the endpoint and count nothing themselves.** The
  repository has one method per role (`fetchClientOverview`,
  `fetchStaffOverview`). The session already knows the role, so neither method
  has to guess which shape the server sent.
- **The backend's buckets win (ADR 0003).**
  - "Needs your input" counts `pending-information` only. Unpaid `submitted`
    cases no longer count there.
  - "In progress" now includes `pending-information`.
  - An unpaid case counts only in the total.
- **The staff's second card reads "assigned this week"**, not "done this
  week". The backend counts assignments, not finished work.
- **Counts re-read when their tab comes back into view.** This uses the same
  `TickerMode` signal as the case list (ADR 0027), now the shared
  `OnTabReturn` mixin. They also re-read on pull to refresh and when a case is
  filed or paid (`casesChangedProvider`).
- **Decoding is defensive.** A count that is missing, negative or not a number
  reads as 0. A `data` that is not an object is a failure. `meta` is not shown.

## Consequences

- The client Home makes one small request instead of a full case-list walk.
- The counts can disagree with the Cases tab for a moment, because each screen
  reads at a different time.
- Search history (`GET /search/history`) is not wired. Its records are
  `/search` queries, not tracking IDs, so "Your recent searches" stays as this
  session's lookups until the backend answers.
