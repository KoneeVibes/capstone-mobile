# 0035 — Account deletion through `DELETE /profile`

- **Status:** Accepted
- **Recorded:** 2026-11-15
- **Supersedes:** the account-deletion half of
  [0032](0032-signed-in-password-reset-and-account-deletion.md)

## Context

ADR 0032 built Delete account against a stub, because the API had no endpoint.
It now has one: `DELETE /profile`, with no body, answering `{status, message}`
and no record. The spec says it permanently deletes the account, its OTP
records and its search history, and keeps the account's cases, invoices and
disputes. Only a `registered-client` may call it; staff and guests get a 403.
Staff are still removed by a super-admin through `DELETE /staff/{id}`.

The token belongs to a user who no longer exists once the call succeeds, and
Profile may not import auth to end the session.

## Decision

- **The repository calls the endpoint.** `ProfileRepository.deleteAccount`
  returns `Result<void>`; `AppFailures.accountDeletionUnavailable` is gone.
- **Only those it can work for see the row.** `SessionUser.canDeleteOwnAccount`
  is true for a registered client only. `SessionUser` gains `isGuest`, read
  from the token's `type`, to tell the two client types apart. Profile asks the
  permission and never compares roles.
- **The app ends the session itself, through a core seam.**
  `accountClosedHandlerProvider` (`core/session/`) is a no-op that
  `authOverrides` fills with `AuthSessionNotifier.endAfterAccountDeletion`.
  That clears the stored session and does not call `POST /auth/signout`: there
  is no account left to sign out of. `ProfileNotifier.deleteAccount` calls the
  handler once the server says the account is gone.
- **Login says why.** `SessionEndNotice` gains `accountDeleted`, shown once as
  "Your account has been deleted."
- **The confirmation says what is kept.** Cases and invoices stay on record,
  so the dialog says so before the user agrees.

## Consequences

- A refusal (403, 404, offline) leaves the session as it was and shows the
  failure's message.
- The email can be registered again afterwards, as far as the spec says; the
  retained cases still carry it as `applicantEmail`, so a new account with the
  same email would see them. That is the backend's rule, not the app's.
- A guest cannot delete an account from the app. If guests ever get the
  endpoint, only `canDeleteOwnAccount` changes.
