# 0009 — Platform plugins sit behind core wrappers

- **Status:** Accepted
- **Recorded:** 2026-10-04

## Context

Plugins such as `image_picker`, `file_picker`, `url_launcher`,
`flutter_secure_storage` and `shared_preferences` talk to the platform over
method channels. Called directly from a feature, they make that feature
untestable without platform mocks, spread plugin-specific error handling across
screens, and turn every plugin upgrade into a search-and-replace —
`file_picker` 11 alone moved its main API.

## Decision

Each plugin is used in exactly one file in `core/`, behind an interface with a
provider:

| Wrapper | Plugin(s) | Failure style |
| --- | --- | --- |
| `MediaPicker` | `image_picker`, `file_picker` | `Result`; `Ok(null)` means the user dismissed the picker |
| `LinkOpener` | `url_launcher` | `Result` |
| `SecureStore` | `flutter_secure_storage` | throws; the auth repository converts |
| `PreferencesStore` | `shared_preferences` | throws; the auth repository converts |

`shimmer` follows the same rule for a different reason: it is imported only in
`AppShimmer`, so the loading animation is identical everywhere.

## Consequences

- Features and tests never touch a platform channel; tests override the provider
  with a fake.
- Plugin quirks are handled once — re-encoding HEIC images, size and type limits,
  "nothing can open this link".
- A new plugin costs one small wrapper before a feature can use it.
