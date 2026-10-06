# 0011 — The staff role comes from the user's own staff record

- **Status:** Accepted
- **Recorded:** 2026-10-06
- **Supersedes:** the staff-role consequence of [0008](0008-session-from-jwt-claims.md)

## Context

The JWT says only `type: staff`. What a staff member may do depends on their
role — `super-admin`, `admin`, `manager` or `regular` — which only
`GET /staff/{id}` returns (`role` on the record). The `id` in the token is the
path parameter. The backend enforces each role's limits; the app should not
offer an action that will be refused.

The rules, agreed with the team on 6 Oct 2026:

| | super-admin | admin | manager | regular |
| --- | --- | --- | --- | --- |
| See the Staff tab (`GET /staff`) | ✓ | ✓ | ✓ | — |
| Add staff | ✓ | ✓ | — | — |
| Edit staff, including their role | ✓ | ✓ | ✓ | — |
| Delete staff | ✓ | — | — | — |
| Assign and re-assign cases | ✓ | ✓ | ✓ | — |

## Decision

- **Sign-in reads the role.** For a staff token, `AuthRepository.signIn` calls
  `GET /staff/{id}` with the new token (passed explicitly — the session does not
  hold it yet) and **fails the sign-in** if it cannot. A staff member without a
  role cannot be placed.
- **A 403 on that call reads as `regular`**, the one role without access to
  staff records, instead of locking them out.
- **The role is stored with the token** in secure storage. A restart opens with
  the stored role at once, then re-reads it in the background so a change made
  on the server arrives without holding the splash. A failed refresh keeps the
  stored role; a 401 ends the session as any request would.
- **`StaffRole` lives in core** (`core/session/`), because the session, the
  router and two features read it. **`StaffPermissions`** holds the rules above
  and is the only thing the UI asks. An unknown role, or a staff session with
  no role stored, gets nothing.
- **Unavailable actions are hidden**, not disabled. The Staff tab is removed
  from the bar and `redirectFor` sends `/staff/members` to the dashboard.
- **Super-admin is shown, never offered.** It is not in the role picker; a
  super-admin record shows its role when edited.

## Consequences

- Staff sign-in is two requests. On a cold Render start it waits for both.
- The checks only decide what is shown; the backend remains the guard.
- Regular staff see assigned cases without the assignee's name, because the
  name lookup reads `GET /staff`. They cannot assign either: the rule first
  agreed was "all staff can assign", but the assignee picker reads the same
  list, so it was narrowed to the roles that can read it (6 Oct 2026).
- `GET /staff/{id}` also returns the name, email and avatar a Profile screen
  needs. Only the role is kept for now.
