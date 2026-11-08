# 0032 — Signed-in password reset by code; account deletion stubbed

- **Status:** Accepted
- **Recorded:** 2026-11-08

## Context

The Profile design has a Reset password row leading to three screens: "Check
your mail" (with "Open email app", "Skip, I'll confirm later" and "resend
email"), then a new password with a confirmation, then "Password changed" with
"Back to profile". The API has no change-password endpoint. A password changes
only through `POST /auth/forgot-password`, which emails a 6-digit code, and
`POST /auth/verify-otp`, which takes the code and the new password together.
The design has nowhere to type the code.

The user also asked for a Delete account action, lower on the Profile tab. The
API has no endpoint for it. `DELETE /staff/{id}` deactivates staff and is for
super-admins only.

## Decision

- **The signed-in reset reuses the signed-out flow's state.**
  `passwordResetFlowProvider` and `otpCooldownProvider` are shared with it.
  `CheckMailScreen` (auth) sends the code to the session's email when it opens,
  unless a code for that email is still within its cooldown, since asking again
  would 409.
- **The code is typed on "Check your mail".** The 6-digit field takes the place
  of "Open email app": opening the mail app's inbox would need a new plugin,
  and the code is needed either way. "Skip, I'll confirm later" goes back to
  Profile, and resend keeps its cooldown.
- **The next two screens are the existing ones, given route names.**
  `ResetPasswordScreen` gets restart and done routes, and
  `PasswordChangedScreen` gets an exit route and label ("Back to profile"). The
  signed-out defaults are unchanged. A wrong code sends the user back to "Check
  your mail" with "Wrong code", as in the signed-out flow.
- **Delete account is built against a stub.** A red row sits in its own card at
  the bottom of Profile, for both roles, behind a confirmation.
  `ProfileRepository.deleteAccount` returns
  `AppFailures.accountDeletionUnavailable` ("Contact support"). The endpoint,
  and what deletion does to the account's cases, are on the backlog for the
  backend lead.

## Consequences

- Checked through the app on 8 Nov 2026: the session **survives** a password
  change. The token in use kept working, and the server also accepted the
  current password as the "new" one. Whether other devices' tokens should be
  revoked is a backend question. If the server ever revokes the token, the
  next request 401s and the app signs out (ADR 0008).
- When the delete endpoint arrives, the repository calls it. The token it
  invalidates ends the session through the same 401 path, unless the app signs
  out on its own first.
