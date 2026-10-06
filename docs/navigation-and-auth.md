# Navigation and auth

[go_router](https://pub.dev/packages/go_router), configured in
`core/navigation/app_router.dart`. Navigate by **name**
(`context.goNamed(AppRoutes.loginName)`), so a path change is made in one place.

## Route map

```
/splash                          wordmark; waits for the session restore
/onboarding                      once per install
/login
/register
  /register/verify               sign-up code
/forgot-password
  /forgot-password/verify        reset code
  /forgot-password/reset         new password
  /forgot-password/done          password changed

/staff  → /staff/dashboard       staff shell
  Dashboard  /staff/dashboard    (+ track/:trackingId)
  Cases      /staff/cases        (+ :caseId)
  Staff      /staff/members
  Profile    /staff/profile

/client → /client/home           client shell
  Home       /client/home
  Search     /client/search
  Cases      /client/cases       (+ :caseId)
  Profile    /client/profile

/legal/privacy-policy, /legal/terms   reserved for the legal screens
```

Each shell is a `StatefulShellRoute.indexedStack`, so every tab keeps its own
history. `AppShell` draws the bottom bar from `AppShell.staffTabs` or
`AppShell.clientTabs`. **Tab order must match branch order**; a debug assert
fails if the counts differ. A branch can be hidden (`hiddenBranches`) without
changing that order: the Staff tab is dropped for roles that cannot list staff.
Both shells mount the same Cases screens; the screen reads the session to hide
staff-only actions.
Why two shells: [ADR 0005](adr/0005-one-app-two-role-shells.md).

## The redirect

One pure function, `redirectFor` (`core/navigation/app_redirect.dart`), decides
every redirect and is unit-tested on its own:

| Who | Where | Goes to |
| --- | --- | --- |
| anyone | `/splash`, `/legal/*` | stays |
| signed out, onboarding not seen | anywhere else | `/onboarding` |
| signed out, onboarding seen | `/onboarding` | `/login` |
| signed out, onboarding seen | a sign-in screen | stays |
| signed out, onboarding seen | anything else | `/login` |
| signed in | `/`, onboarding or a sign-in screen | their home tab |
| signed in | the other role's shell | their home tab |
| staff without `canViewStaff` | `/staff/members` | the dashboard |

The router re-runs it whenever `sessionProvider` or `hasSeenOnboardingProvider`
changes (`refreshListenable`). So **a successful sign-in or sign-out needs no
navigation code**: change the session, and the user is moved.

## The session

```
SecureStore ◀── AuthRepository ◀── AuthSessionNotifier ──▶ sessionProvider (core)
  (token, staff role)              (AuthSession?)           (SessionUser?)
```

- **Sign-in** returns a JWT, stored in the Keychain / Keystore. Its payload is
  `{id, type, iat, exp}`; `type` is `staff`, `registered-client` or
  `guest-client`. Both client types share the client shell. An unknown type is
  refused with `AppFailures.unsupportedAccount` and never stored.
- **The token is decoded on the device, never verified.** The device has no key,
  and the server checks every request. There is no `/me` endpoint, so the app
  knows only the user's id and type.
- **Staff role.** For a staff token, sign-in also reads `GET /staff/{id}` for
  the role and fails if it cannot (a 403 reads as `regular`). The role is
  stored with the token, and `SessionUser.permissions` (`StaffPermissions`,
  `core/session/`) turns it into what the UI may show. Rules and reasoning:
  [ADR 0011](adr/0011-staff-role-from-own-record.md).
- **Restore.** On launch the splash waits for `sessionRestoreProvider`: the
  stored token, minus one that has expired. A staff session opens with its
  stored role and re-reads it in the background. Tokens last 24 hours; there is no
  refresh, so an expired session means signing in again. A fresh install that
  has not seen onboarding discards any token left in the Keychain, which
  survives an uninstall on iOS.
- **Expiry while in use.** A 401 on an authenticated request calls
  `AuthSessionNotifier.expire()`. It clears the session once, however many
  requests failed together, and leaves a notice that the login screen shows
  ("Your session has expired").
- **Sign-out** tells the server (best effort), then forgets the token whatever
  the server says. The sign-out call's own 401 is not mistaken for an expiry.
- **Per-user data** resets on any session change; see
  [State management](state-management.md#one-users-data-watches-the-session).

## The code flows

Codes are six digits, emailed, valid for about ten minutes, and the server
refuses a second code for the same email for ten minutes. The code screen counts
those ten minutes down before offering "Send code again".

**Sign-up (clients only):** register form → `POST /auth/signup` → code screen →
`POST /auth/verify-otp` (`otpType: sign-up`, every user field again) → automatic
sign-in with the password just typed → client home. The form's details stay in
memory (`signUpFlowProvider`) until then; a restart mid-flow starts again.

**Password reset:** email → `POST /auth/forgot-password` → code screen →
new-password screen → `POST /auth/verify-otp` (`otpType: password-reset`, only
`password` and `confirmPassword`) → "Password changed". The API checks the code
**only together with the new password**, so the code screen just collects it. A
rejected code sends the user back to the code screen with "Wrong code, please
try again".

Staff accounts are created by a super-admin or admin (`POST /staff`) and never
register. No
password is issued: a new staff member sets one through "Forgot password".

## Not yet built

- A real Profile screen — clients need a `/me` endpoint or equivalent; staff
  could use `GET /staff/{id}`, which sign-in already calls.
- Deep links. None are configured, so the app always starts at `/splash`. If
  they are added, `redirectFor` must hold a cold-start link until the session
  restore finishes. Otherwise the link is judged while the session still reads
  as signed out, and lands on onboarding or login.
