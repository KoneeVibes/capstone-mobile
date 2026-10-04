# 0003 — The backend is the source of truth over the designs

- **Status:** Accepted
- **Recorded:** 2026-10-04 (decided while building Staff, August 2026)

## Context

The designs and the live API disagree often. The Staff designs showed four roles
the API does not have (Property Agent, Legal Reviewer…) and a "Suspended" status;
the API has `admin`/`manager`/`regular` and `active`/`inactive`. The Cases
designs drew budgets, timelines and notes that are not on the record. A status
control appeared on a form that no endpoint accepts a status for.

## Decision

- **Enums and fields come from the API.** Values the API does not have are
  dropped from the UI, not faked.
- **Entities are shaped to the wire**, not to the mock-ups. A drawn field that
  does not exist is deleted, not kept as a permanently-null property.
- **A control that cannot work is removed**, with the reason recorded.
- **Never send the server an allow-list of values it owns.** The cases list once
  went blank because the app filtered by the six statuses it knew, and the
  backend added two more. Ask for everything; filter on the device.

## Consequences

- The UI never offers an action the backend will reject.
- Some screens look sparser than their designs. Each gap is recorded so it can
  return when the API grows the field. One did: the case reference the designs
  showed arrived later as `trackingId` and is now displayed.
- Models decode defensively: undocumented fields appear without warning, and
  unknown enum values must render (as an absent label) rather than crash.
