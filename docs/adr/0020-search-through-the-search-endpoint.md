# 0020 — Search cases and staff through `GET /search`, one tab at a time

- **Status:** Accepted
- **Recorded:** 2026-10-24

## Context

The backend added `GET /search`. It takes `q` (2–100 characters) and one or
more `flag`s: `case`, `staff`, `registered-client`, `guest-client`. It answers
`{cases: [...], staff: [...]}`, keyed by category. Probed live:
- `meta` holds only `page` and `perPage` (at most 100), with no totals.
- A search with no match is a 404 that still carries an empty result.
- Results respect each role's visibility. Clients may search cases only.

The Staff tab had carried a disabled search bar since August, waiting for a
search parameter on `GET /staff`. The Cases tab had no search. No design was
shared for search.

## Decision

- **A bar on each tab, not a global search screen.**
  - The Cases tab, in both shells, searches cases (`flag=case`).
  - The Staff tab searches staff (`flag=staff`).
  - Each feature calls `/search` with its own flag through its own datasource,
    so no feature imports another, and results reuse the tab's own rows and
    actions.
- **Clients are not searched yet.** Staff could find registered and guest
  clients, but the app has no screen to open one on.
- **One request, the API's largest page (100).** With no totals in `meta`,
  paging is guesswork, and over 100 hits is a search to narrow.
- **The query is debounced** (`AppConstants.searchDebounce`) and trimmed.
  Fewer than two characters is "not searching": the normal list shows, and no
  request is sent.
- **The 404 means "no match"**, the same reading as the cases list's 404.
- **A found case is drawn from the Cases list's copy when the list holds it**
  (`CasesListState.latestOf`), so a status changed from a result card shows at
  once. The filter tabs filter results too.
- **A staff edit or removal re-runs the search**, as it already re-reads the
  list.
- **Failed searches are not auto-retried.** The error state offers a retry.

## Consequences

- A client's search returns assigned and closed cases that `GET /case` hides.
  Opening one 404s until the backend fixes client visibility (ADR 0019).
  *Fixed on the backend; checked live 26 Oct 2026 (ADR 0021).*
- Regular staff may search staff, though `GET /staff` refuses them. It is
  harmless: they have no Staff tab. *Intended, the backend lead confirmed
  (26 Oct 2026): a future feature needs it.*
- Client search, or a global search, can be added later on the same endpoint.
