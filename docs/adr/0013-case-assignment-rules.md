# 0013 — Who can take a case, and what an assignment writes

- **Status:** Accepted
- **Recorded:** 2026-10-07 (decided 2026-08-31, while building Cases)

## Context

`PATCH /case/{id}` takes a `status` and an `assigneeId`, and a case carries only
the bare `assigneeId` — no endpoint lists assignable people or expands the id.
Verified live: the PATCH accepts `assigneeId` on its own and leaves the status
untouched. The designs cover assignment only; no screen changes a status.

## Decision

- **Every status except `submitted` can be assigned and re-assigned.** A case
  whose payment has not cleared is not the team's to pick up, so the button
  greys out with a line saying why.
- **The write carries `status: assigned` only from `payment-validated`.**
  Otherwise it sends the assignee alone, so re-assigning never moves a case
  backwards through its lifecycle.
- **Names come from `GET /staff`, joined on `assigneeId` on the device.** The
  picker offers `active` staff only; names resolve from the unfiltered list, so
  a case held by someone since deactivated still shows who has it. If that
  request fails the row shows no name rather than an error.
- **A successful assign pushes the returned record into the list and detail**
  instead of re-fetching, so the screen never contradicts its own confirmation.
- Clients reuse the Cases screens without the assign button or the staff join
  (`GET /staff` is staff-only).

## Consequences

- Mobile can only ever write `assigned`; the other statuses are read-only here
  until the team decides staff drive the lifecycle from the app.
- A closed or suspended case can still change hands — nothing in the designs
  says otherwise. Revisit if that turns out wrong.
- One extra request per list load for names. An expanded `assignee` on the case
  would remove it and the join.
