# 0021 — Suspend a case through `DELETE /case/{id}`; re-assign to lift it

- **Status:** Accepted
- **Recorded:** 2026-10-26
- **Supersedes:** in [0019](0019-case-status-actions-and-reports.md), "suspend is `PATCH {status}`" and "`status: assigned` only from `payment-validated`"

## Context

ADR 0019 sent suspend as `PATCH /case/{id}` `{status: suspended}`, as agreed
on the 24 Oct call. The server refused it (400 "Invalid status. Cannot
proceed."), and `suspended` was never in the PATCH enum. The backend lead's
answer (26 Oct 2026): suspend is `DELETE /case/{id}`. The user confirmed it
on a throwaway case (`PI-47RKXC36`): 200, "Case suspended successfully.", and
`data` is the whole case with `status: suspended` and a new `statusHistory`
entry. Like deleting a case before it, it is super-admin only.

## Decision

- **Suspend is a write of its own.** `CasesRepository.suspendCase` sends
  `DELETE /case/{id}` and decodes the returned case. It is not an
  `updateStatus`, which now carries accept and close only.
- **Nothing else moves.** The ⋮ action, its confirm dialog, the matrix
  (super-admin; payment-validated through under-review) and how the returned
  case replaces the one on screen are unchanged from 0019.
- **Re-assigning lifts a suspension, and says so.** A super-admin
  re-assigns a suspended case with `status: assigned` alongside `assigneeId`
  (backend lead, 26 Oct 2026). The app first sent the assignee alone, and
  lifting failed.
  `CaseStatus.advancesOnAssign` now covers `suspended` as well as
  `payment-validated`. Every other re-assign still sends `assigneeId` alone, as
  a change of hands (0013).
- **Lifting means picking someone else.** The assign sheet keeps Confirm greyed
  out for the current holder, a suspended case included. This was left as it
  is by decision (26 Oct 2026): lifting a suspension mostly hands the case to
  someone new.

## Consequences

- `DELETE` on this resource does not remove anything, despite the verb. The
  datasource says so where it sends it.
- The other 0019 gaps are closed on the backend, checked live on 26 Oct 2026:
  clients see their own cases in every status, and Cloudinary serves PDFs.
