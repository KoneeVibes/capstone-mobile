# 0029 — Recent searches come from the server's search history

- **Status:** Accepted
- **Recorded:** 2026-11-08

## Context

"Your recent searches" (client Home, and the tracking lookup that both roles
reach) listed only this session's lookups, kept in memory. `GET /search/history`
held only `/search` queries, not tracking IDs (ADR 0028). The backend has since
made tracking write to it. This was checked on the wire on 8 Nov 2026, with a
client token and a regular staff token:

- `GET /case/track/{trackingId}` with a bearer token saves the ID to the
  caller's history. Tracking it again updates the same record's `updatedAt` and
  adds no new record. A 404 saves nothing.
- A history record is `{id, requester, query, flag[], status, createdAt,
  updatedAt}`, newest first. It has no case status or address.
- `DELETE /search/history/{id}` hides a record.
- The tracking response now carries `propertyAddress`, and `assigneeName` on
  each `statusHistory` entry.

## Decision

- **The list is the server's history.** `recentSearchesProvider` is a
  `FutureProvider` over `GET /search/history`. It waits while signed out and
  shows the newest five. It reads one page of 20, not every page: only the top
  of the list is shown.
- **Only tracking IDs are kept.** The website's free-text `/search` queries
  share the history. Each `query` is normalised like typed input, and anything
  that is not a tracking ID is dropped. An ID that appears twice is listed once,
  at its newest.
- **A tile shows the ID and when it was searched** ("Searched 2 hours ago").
  The record carries no status or address. Joining them in would cost another
  request, so the tile leaves them out. Tapping a tile still opens the live
  status.
- **The list is re-read** after every successful lookup, when its tab comes
  back into view, and on Home's pull-to-refresh. It is not changed locally.
- **No remove control yet.** There is no design for one, though the endpoint
  exists.
- **Tracking reads one request.** The address and assignee names come from the
  tracking response. The `GET /case` and `GET /staff` joins are gone.

## Consequences

- Recent searches now persist across restarts and devices, and match the
  website.
- A lookup made while signed out is not recorded. In the app that cannot
  happen: every lookup screen is behind sign-in.
- The address shown is the free-text `propertyAddress` only. The removed join
  fell back to city and state when that field was blank.
