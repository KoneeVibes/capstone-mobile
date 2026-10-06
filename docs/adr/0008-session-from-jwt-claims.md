# 0008 — The session is the JWT, read but not verified

- **Status:** Accepted
- **Recorded:** 2026-10-04

## Context

`POST /auth/signin` returns only `{status, token}` — no user record — and there is
no `/me` endpoint. The token's payload is `{id, type, iat, exp}`, where `type` is
`staff`, `registered-client` or `guest-client`. Tokens last 24 hours and cannot
be refreshed.

## Decision

- **The token is the session.** It is stored in the Keychain / Keystore
  (`flutter_secure_storage`) and decoded on the device for its id, type and
  expiry.
- **Decoded, not verified.** The device has no signing key, and the server
  checks the signature on every request, so client-side verification would add
  nothing.
- **`type` picks the shell.** Both client types share the client shell. An
  unknown type is refused at sign-in and never stored, rather than guessed.
- **Expiry is enforced twice**: a stored token past `exp` is dropped on launch,
  and any 401 on an authenticated request ends the session.
- **The onboarding flag lives in `shared_preferences`.** Preferences are wiped on
  uninstall but the iOS Keychain is not, so a session is only restored once
  onboarding has been seen on this install.

## Consequences

- The app knows the user's id and role, but not their name or email. A real
  Profile screen needs a `/me` endpoint or equivalent.
- The staff sub-role (admin, manager, regular) is not in the token, so the UI
  cannot yet hide actions a regular staff member is not allowed to take.
  *Superseded by [0011](0011-staff-role-from-own-record.md): the role is read
  from `GET /staff/{id}` at sign-in.*
- Users sign in again at least once a day.
