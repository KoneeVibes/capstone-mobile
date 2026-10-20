# 0016 — Staff home "My queue" and case chat, built as mock UI

- **Status:** Accepted
- **Recorded:** 2026-10-19

## Context

The team redesigned the staff home. The Dashboard tab, which until now was the
tracking-ID lookup (`DashboardScreen`), becomes a greeting, two headline counts
and a **My queue** list: one card per case, each with a status badge, a due
indicator and a single action whose label depends on the status. A separate
per-case **Chat** screen is also wanted, gated by an explicit *Open
conversation → … → Close conversation* flow.

None of this has endpoints yet, and "cases will be changing with new flows." So
the work lands as a **UI-only layer** against mock data, with `TODO(backend)`
markers where the real endpoints will plug in. The design shows a **Disputed**
status that `CaseStatus` does not have, and greets the member by name — which the
app cannot do reliably, since the JWT carries no name and `GET /staff/{id}`
returns 403 for `regular` staff.

## Decision

- **The Dashboard tab root is now `StaffHomeScreen`** (dashboard feature), which
  reuses `OverviewCard` and follows the `ClientHomeScreen` shape. The tracking
  lookup keeps its routes but moves to a child, `/staff/dashboard/lookup`,
  reached from a search entry in the home header. The four staff tabs are
  unchanged.
- **The queue is mock and dashboard-local.** A `QueueStatus` enum models the
  eight lifecycle values plus `disputed`, mirroring how `TrackingStatus` already
  copies `CaseStatus` rather than importing it. A pure `actionFor(status)` maps
  each status to its button; the filter tabs (All / New / Assigned / Closed)
  group the statuses so the list is not nine tabs wide.
- **Actions follow the team's rule.** Everything routes to the case detail
  except `assigned` — the one confirmed one-click action (accept in place, a
  snackbar) — and `pendingInformation`, which opens the chat. `submitted` and
  `closed` show their button disabled.
- **Chat is a new feature, mock, and top-level.** `CaseChatScreen` lives above
  the shell (`/staff/chat/:caseId`), so it opens full screen with no bottom nav
  and is reachable both from the queue and from a new action on the case detail
  app bar. A `ChatConversation` carries a `notOpened | open | closed` state;
  typing and sending are only allowed while open, and open/close raise the
  existing `showMessage` snackbars. Features still do not import each other —
  the queue and case detail open the chat by route name.
- **The greeting stays generic ("Welcome back").** Wiring the real name is
  deferred to its own task rather than reshaping the session for it now.

## Consequences

- Queue cards route to the real case-detail screen with a mock id, so detail
  shows its normal not-found until the endpoint lands — the plumbing is correct
  ahead of the data.
- `Disputed` has no server value and borrows the amber warning tint; both the
  status and the colour are provisional, to confirm with design and backend.
- `AppButton` gained a `soft` variant for the queue card actions; additive, and
  available to any other low-emphasis brand action.
- Everything new is covered by unit tests (the action map, the filter grouping,
  the chat state machine). The backlog tracks the endpoints each mock stands in
  for.
