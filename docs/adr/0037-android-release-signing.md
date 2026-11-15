# 0037 — Android release builds are signed with an upload key kept out of git

- **Status:** Accepted
- **Recorded:** 2026-11-15

## Context

Release builds were signed with the debug key, as the Flutter template leaves
them. Google Play refuses a debug-signed bundle, and the debug key is the same
on every machine that has the Android SDK. The app has not been published yet,
so no signing identity is fixed.

## Decision

- **One upload key, for Play App Signing.** Google holds the app signing key;
  this key only proves an upload is ours, so it can be reset through Play
  support if it is lost. Alias `upload`, RSA 2048, valid to 2054.
- **The keystore and its passwords are never committed.** The keystore sits
  at `android/app/propertyintel-upload.jks` and its path, alias and passwords
  in `android/key.properties`; `android/.gitignore` ignores both
  (`**/*.jks`, `key.properties`). `android/key.properties.example` is the
  committed template.
- **Gradle reads `key.properties` when it is there.** With it, the `release`
  build type uses the upload key. Without it (a fresh clone, a teammate
  without the key) release falls back to the debug key so
  `flutter run --release` still works; that build cannot ship.
- **The application ID stays** `com.capstoneglobalhq.propertyintel.propertyintelmobileapp`.
  It is permanent once published.
- **iOS is not covered.** It is on automatic signing with no team set, and
  needs a Mac.

## Consequences

- Whoever cuts a release needs the keystore file and `key.properties`. Both
  exist only in one working tree, so they must be backed up somewhere else; a
  fresh clone or a `git clean -x` has neither.
- A build made without the key looks like any other release build; check the
  signer before uploading (`docs/tooling.md`, "Release signing").
- CI, when there is one, takes the keystore and passwords from its secret
  store and writes `key.properties` at build time.
