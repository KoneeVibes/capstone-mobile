# 0025 — Disputes write for real, on a closed case

- **Status:** Accepted
- **Recorded:** 2026-10-28
- **Supersedes:** the disputes half of [0017](0017-case-actions-and-disputes.md)

## Context

ADR 0017 kept disputes in memory until the backend had endpoints for them.
The endpoints now exist:

- `POST /dispute` is multipart: `caseId`, `title`, `description`, and up to
  five `attachment` files (JPG, PNG or PDF, 5 MB each). The 201 has no `data`.
- `GET /dispute/case/{caseId}` is a paginated list. "None" is a 404, "Case
  disputes not found".
- `PATCH /dispute/{id}` takes JSON `{rejectionNote}` and declines the
  dispute, returning it.
- A dispute is `open | accepted | rejected`, and carries `rejectionNote`
  and the attachment URLs.

No endpoint accepts a dispute. The 24 Oct call had a client dispute an
**accepted** case. The swagger says **closed**, and the Status Matrix's
"report must be re-submitted" fits that. The user ruled for the swagger
(28 Oct 2026).

## Decision

- **A client disputes a closed case only.** `CaseStatus.canBeDisputed` is
  `closed`. On any other paid case, Raise dispute shows greyed out; while
  the case is unpaid, it is hidden. The API allows one open dispute per case,
  so Raise hides while one is open and comes back after a decline.
- **Disputes stay in the cases feature.** They have their own
  `DisputesRepository`, which the case detail and the dispute screen read
  through `caseDisputesProvider`. That provider now watches the session.
- **Raising re-reads the list**, since the response carries no record.
  **Declining** puts the returned dispute into the list.
- **Accepting a dispute is a case write:** `PATCH /case/{id}` with
  `status: disputed` (`CaseUpdateNotifier.takeInDispute`). The case moves to
  `disputed`, the assignee submits the report again (`takesReport`), and the
  disputes are re-read. If the case says `disputed`, the dispute reads as
  taken in, whatever its own record says.
- **Who answers**, only while the dispute is open and the case still
  closed:
  - **Accept** is the assignee's alone (`CaseViewer.canAcceptDispute`). The
    server refuses anyone else with 403 "Only the assigned staff member may
    accept the dispute" (checked live, 28 Oct 2026).
  - **Decline** is the assignee's, or any manager's
    (`canDeclineDispute`). As in 0019, no record names the assignee's
    manager.
- **Evidence** is limited to 5 MB per file on the device
  (`MediaPicker.pickDocuments(maxBytes:)`). Attachments open in the app like
  any case file (0022).

## Consequences

- The case detail makes one more request (`GET /dispute/case/{id}`) for
  every role.
- 0017's "any number of disputes once paid" and its in-memory evidence are
  gone. Disputes now survive a restart and reach the other role's device.
- On 28 Oct 2026, raising a second dispute on a case after a decline failed
  with a server 500. The app shows the server's message and keeps the form
  filled in. Raise stays offered there, because the API intends to allow a
  new dispute once none is open.
- Accepting was verified end to end by the assignee on a new case
  (28 Oct 2026). The server refuses every other role with 403.
