# 0026 — The dispute section appears on a closed case only

- **Status:** Accepted
- **Recorded:** 2026-10-30
- **Supersedes:** the greyed-out Raise dispute of [0025](0025-disputes-write-for-real.md)

## Context

Under 0025 a client saw Raise dispute on every paid case, greyed out with
"You can raise a dispute once the search is closed." until the case closed.
The team asked for the dispute section to appear only once the case is closed,
instead of showing it blocked.

The backend answered 0025's open points on 30 Oct 2026. These are server checks;
the swagger shows no new fields:

- A case can be disputed only once it is **closed**, which settles call versus
  swagger.
- A new dispute may follow a declined one. The 500 on re-raising is fixed.
- Only the assignee, or the assignee's manager, may decline.

## Decision

- **Raise dispute shows on a closed case only.** On any other status the
  client sees no Dispute part and no greyed-out button. It still hides while a
  dispute waits for an answer. It is offered in one place at a time: the
  Dispute section's "+ Raise dispute" until the first dispute is raised, then
  the footer's "Not satisfied with the outcome? Raise dispute" (user, 30 Oct).
- **Disputes already raised stay listed** after the case moves on (`disputed`,
  then `under-review`), so the client can see theirs was taken in.
- **Decline stays offered to the assignee and to managers.** No record names the
  assignee's manager (0019). A manager can only see their own team's cases, so
  any manager who can open a case is already the assignee's manager.

## Consequences

- `CasePropertyUpdate` loses `showRaise`. A non-null `onRaise` is what offers
  Raise dispute.
- If loading disputes fails on a case that is not closed and has no report,
  the client sees nothing rather than an error, the same as a case with no
  disputes.
- The Decline rule depends on a manager seeing only their own team's cases.
  If the backend widens that view, the app would offer Decline to managers
  the server refuses, and it would need the assignee's manager on the record.
- Re-raising after a decline was checked live on 30 Oct 2026 and works. The
  same run found a manager's decline refused (401, "Only the assigned staff
  member may reject the dispute"). That is raised with the backend, and this
  Decline rule stands until it answers.
