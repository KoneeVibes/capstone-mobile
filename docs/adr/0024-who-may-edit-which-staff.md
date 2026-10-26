# 0024 — Who may edit which staff

- **Status:** Accepted
- **Recorded:** 2026-10-26
- **Supersedes:** the "Edit staff" row of [0011](0011-staff-role-from-own-record.md)

## Context

ADR 0011 let a super-admin, an admin or a manager edit any staff record,
including its role. That meant a manager could edit an admin or a super-admin,
or make someone an admin. Super-admins are created directly in the database,
never through the app. The user ruled on 26 Oct 2026.

## Decision

- **Edit is per row.** `StaffPermissions.canEditStaffMember(role)`:

  | Editor ↓ / row → | super-admin | admin | manager | regular |
  | --- | --- | --- | --- | --- |
  | super-admin | ✓ | ✓ | ✓ | ✓ |
  | admin | — | ✓ | ✓ | ✓ |
  | manager | — | — | ✓ | ✓ |
  | regular | — | — | — | — |

- **The role picker offers only what the editor could still edit**
  (`grantableRoles`). A manager can choose manager or regular; an admin or a
  super-admin can choose admin, manager or regular. Super-admin is never
  offered (ADR 0011). A role the record already holds still shows.
- As in ADR 0011, a row the user may not edit has no Edit; nothing is shown
  disabled.

## Consequences

- A manager can no longer promote anyone to admin from the app.
- The app only decides what is shown. Whether the backend refuses the same
  edits has not been checked.
