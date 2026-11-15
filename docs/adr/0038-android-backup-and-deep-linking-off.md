# 0038 — Android backup and Flutter deep linking are switched off

- **Status:** Accepted
- **Recorded:** 2026-11-15

## Context

Two platform defaults were on because nothing said otherwise.

- **Android Auto Backup.** With no `android:allowBackup` in the manifest,
  Android copies the app's data to the user's Google account and to a new
  phone. That includes the `flutter_secure_storage` preferences, whose values
  are encrypted with a Keystore key that never leaves the old device. On the
  new phone the token is there but cannot be decrypted. `restoreSession`
  survives that by signing out, but the copy serves no purpose.
- **Flutter deep linking.** It is on by default, so any app on the device can
  open any route with an explicit `VIEW` intent. `redirectFor` still guards
  sign-in, but no deep link has been designed and none is wanted yet.

## Decision

- **Backup is off entirely.** `android:allowBackup="false"`, plus
  `res/xml/data_extraction_rules.xml` excluding every domain from both cloud
  backup and device transfer. The rules file is needed as well: on Android 12
  and above `allowBackup` alone does not stop a device-to-device transfer.
- **Nothing is carved out.** The only other stored state is the
  onboarding-seen flag; keeping it was not worth depending on a plugin's
  preference file name.
- **Deep linking is off on both platforms.** `flutter_deeplinking_enabled`
  is `false` in the Android manifest and `FlutterDeepLinkingEnabled` is
  `false` in `Info.plist`.

## Consequences

- A restored or transferred phone behaves like a fresh install: onboarding
  shows again and the user signs in.
- iOS backup is unchanged and not covered here. A Keychain item that comes
  back on a restore is readable, and a fresh install that has not seen
  onboarding does not resume an old session.
- Opening a route by intent no longer works, including from `adb` while
  testing; reach screens through the UI.
- Real deep links, when designed, re-enable the flag (or add `app_links`)
  and must hold a cold-start link until the session is restored
  (`docs/navigation-and-auth.md`).
