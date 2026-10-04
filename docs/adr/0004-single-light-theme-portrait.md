# 0004 — One light theme, portrait only

- **Status:** Accepted
- **Recorded:** 2026-10-04

## Context

The designs are light-only and portrait-only. Supporting a dark theme or
landscape would mean designing, building and testing every screen twice, with
no design to build to.

## Decision

- `ThemeMode.light` is pinned in `app.dart`; there is no dark theme.
- Both native launch screens are pinned light. Android has no `values-night`
  resources — the Flutter template's inherited black theme flashed on dark-mode
  devices — and the iOS storyboard hard-codes white.
- Portrait is enforced in three places: `main.dart`, the Android manifest and
  `Info.plist`, so the app never renders sideways even for a frame.
- System text scaling is honoured but clamped to 0.85–1.3.

## Consequences

- One set of colour tokens; no theme-dependent styling.
- Users who rely on dark mode or a fixed landscape mount are not served — noted
  in [Accessibility](../accessibility.md).
- Revisiting this means a design for every screen first, then a new ADR.
