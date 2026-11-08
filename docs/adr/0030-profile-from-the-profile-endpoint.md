# 0030 — The Profile tab reads and writes `/profile`

- **Status:** Accepted
- **Recorded:** 2026-11-08

## Context

Both roles' Profile tab was a placeholder: the API had no `/me`, so there was
no way for a client to read their own name. The backend has since added
`GET /profile` and `PUT /profile`. Checked on the wire on 8 Nov 2026 with a
client token and a regular staff token:

- `GET /profile` answers for both roles (regular staff included, who get a 403
  from `GET /staff/{id}`) with `{id, firstName, middleName, lastName, phone,
  avatar}` plus an undocumented `_id`. Unset fields are `null`. It has **no
  email**, and `id` equals the session's user id.
- `PUT /profile` is multipart. It takes any of `firstName`, `middleName`,
  `lastName`, `phone` and an `avatar` file (JPG, JPEG or PNG). It refuses an
  empty update with a 400 and returns the saved profile. Sending `""` clears a
  field; it then comes back as `""`, not `null`. An avatar on its own is
  stored on Cloudinary and returned as a URL. All three were checked through
  the app.

The design adds Update Profile, Reset password and Sign out rows, a bell, and
a photo with an edit badge. The staff home greeting has waited for a name
since ADR 0016.

## Decision

- **A `profile` feature owns the record.** `profileProvider` is an
  `AsyncNotifier` over `GET /profile`. Like every provider of one user's data,
  it waits while signed out. A save puts the server's record straight into
  state, with no re-read. It is auto-disposed, so the next user never sees
  this one's profile (ADR 0033).
- **The email comes from the session**, as typed at sign-in. A session stored
  before the app kept the email shows no email line and no Reset password row.
- **Update Profile sends only what changed.** If nothing changed, it closes
  without a request, since the API refuses an empty update. An emptied field
  is sent as `""` to clear it. The email cannot be edited here.
- **The edit badge on the Profile tab uploads at once**, because the API takes
  a photo on its own. On Update Profile, a new photo waits for Save.
- **Other features' parts are passed in.** The router gives `ProfileScreen`
  the notifications bell and auth's `SignOutTile`, and Reset password is
  reached by route name (ADR 0032). The Terms and Privacy links from the
  placeholder stay as rows: the design drops them, but the stores expect a
  privacy policy in the app.
- **The account screens open full screen**, each role on its own copy:
  `/{staff|client}/account/edit`, `.../password`, `.../password/reset`,
  `.../password/done`, and `/{staff|client}/notifications`. They sit under the
  role's prefix, so `redirectFor` needs no new rule.
- **The staff greeting uses the first name** through a new core seam,
  `signedInFirstNameProvider`. Core declares it as null, and
  `profileOverrides` (in `main.dart`, beside `authOverrides`) fills it from the
  profile. The dashboard never imports profile, and greets "Welcome back" until
  the name arrives.

## Consequences

- The staff home now requests `GET /profile` on load, through the seam.
- A profile change made on the website shows on the next pull-to-refresh or
  sign-in, not live.
- `AppMenuTile` and `AppBackButton` moved to `shared/widgets`. The back button
  was auth's, and three features now use it.
