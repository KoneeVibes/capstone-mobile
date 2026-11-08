# 0034 — A client's applicant name and phone come from their profile

- **Status:** Accepted
- **Recorded:** 2026-11-08

## Context

The property search locks a client's applicant email to the sign-in email
(ADR 0012), because a client files for themselves. Name and phone stayed free
text, so every client typed details their profile already holds, and could
file under any name.

## Decision

- **A client's applicant name is their profile's full name, read-only**, like
  the email.
- **A client's phone is prefilled from the profile but stays editable**: the
  number to reach them about this property may not be the one on the account.
  It fills only an empty field, so it never overwrites what was typed.
- Both arrive through new core seams beside the first-name one (ADR 0030),
  `signedInFullNameProvider` and `signedInPhoneProvider` in
  `core/session/signed_in_name.dart`, filled by `profileOverrides`. Property
  search never imports profile.
- **The name locks once the profile arrives.** It loads after the form opens,
  so until then (or if it fails) the field stays editable rather than blocking
  the search.
- **Staff still type all three**, since they file for someone else.

## Consequences

- Opening the search as a client now requests `GET /profile` if it is not
  already loaded.
- A client who wants another name on the case changes it in Profile first.
