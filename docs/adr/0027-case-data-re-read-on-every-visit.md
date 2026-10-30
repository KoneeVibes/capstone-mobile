# 0027 — Case data is re-read on every visit

- **Status:** Accepted
- **Recorded:** 2026-10-30

## Context

The case list, a case's detail and its disputes were kept for the whole
session. A write on this device patched them, but a change made by the other
role (a client raising a dispute, staff declining one) showed only after a
pull to refresh. Reopening a case even showed the copy from its first visit.
The team asked for the case list to be disposed and fetched fresh.

The list cannot simply dispose itself. Both shells keep each tab alive in an
indexed stack, so the list screen never leaves the tree.

## Decision

- **A case's detail and disputes are `autoDispose`.** Leaving the case drops
  them, and every open fetches fresh behind the usual skeleton. Writes still put
  their returned record into the screens holding it (they check `ref.exists`).
- **The list re-reads on every visit** (`CasesListNotifier.revisit`): when the
  Cases tab or the staff home comes back into view, and when the user comes
  back from a case opened from the list. The rows stay on screen while it
  loads. A reload already under way is joined rather than repeated.
- **A tab "coming back" is detected from `TickerMode`.** go_router turns a
  hidden branch's tickers off, so `core/` needs to know nothing about cases
  (`RevisitCasesList`).

## Consequences

- More requests. Each case open costs a detail read and a dispute read, and
  each return to the list costs a full list walk (0006). On the cold-starting
  host that is felt only on the first one.
- A reload that fails replaces the list with the error state and its retry,
  as pull to refresh always has.
- Opening a case from the staff home switches to the Cases tab, so the list
  re-reads then, not when you come back from that case.
