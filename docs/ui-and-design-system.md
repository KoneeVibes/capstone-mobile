# UI and design system

## Tokens — no literals in widgets

| Need | Use | Lives in |
| --- | --- | --- |
| A colour | `AppColors.*` | `core/theme/app_colors.dart` |
| A text style | `AppTextStyles.*` | `core/theme/app_text_styles.dart` |
| A size, gap, radius, icon size | `AppSizing.*` | `core/sizing/app_sizing.dart` |
| A date, amount, phone, name, countdown | `AppFormatters.*` | `core/formatting/app_formatters.dart` |
| An asset path | `AppAssets.*` | `core/constants/app_assets.dart` |

No hex values and no bare numbers for layout in widget code. If the token you
need does not exist, add it with a name that says what it is for
(`AppSizing.loginHeroFraction`, not `size42`).

## Theme

**One light theme, always.** `ThemeMode.light` is pinned, both native launch
screens are pinned light, and there is no dark variant to keep in step
([ADR 0004](adr/0004-single-light-theme-portrait.md)). The theme
(`AppTheme.light`) styles inputs, sheets, dialogs and app bars, so most widgets
need no styling of their own.

## Copy

- **Screen copy lives on the screen that renders it.** There is no shared
  strings file and no localisation yet. The app is English-only.
- Exceptions: error wording (`ErrorHandler`, `AppFailures`) and labels a caller
  passes into a shared widget.

## Loading states

- **Content with a known shape loads as a skeleton** — `AppShimmer` around
  `AppShimmerBox` blocks laid out like the real content, so nothing jumps when
  data arrives. Put the shimmer *inside* the card, around the blocks only;
  wrapping the card greys out its background too.
- **Spinners only for work with no shape**: a submit (`AppButton(isLoading:)`),
  pull-to-refresh, verifying a code.

## Shared widgets

Check `lib/shared/widgets/` before writing a widget. Every public member there is
documented (enforced by `public_member_api_docs`; see
[Coding standards](standards.md#documenting-shared-code)), so the source is the
reference. In summary:

| Widget | Use it for |
| --- | --- |
| `AppButton` | every button: primary, secondary (outlined), destructive; loading state built in |
| `AppTextField` | labelled form fields; `showLabel: false` for placeholder-only designs |
| `AppSearchField` | pill search input |
| `AppOtpField` | one-time codes: boxes over one hidden field, so paste and autofill work |
| `AppChip`, `AppChoiceChip` | status pills; selectable filter or role chips |
| `AppAvatar` | initials or a photo, falling back to initials on error |
| `AppBottomNav` | the tab bar (driven by `AppShell`) |
| `showAppBottomSheet` / `AppBottomSheet` | forms in a sheet, keyboard-aware |
| `showAppConfirmDialog` | yes/no confirmation, with or without an icon |
| `AppStateView` | centred loading, empty and failure states |
| `AppShimmer`, `AppShimmerBox` | skeletons |
| `PlaceholderScreen` | a route whose screen is not built yet |

Feature-only widgets stay in the feature (`features/<name>/presentation/widgets/`)
until a second feature needs them; then they move to `shared/` and get documented.

## Layout rules

- **Portrait only**, enforced in `main.dart`, the Android manifest and
  `Info.plist`.
- Screens that can hold a keyboard scroll as one piece, so a focused field is
  never covered (`AuthPage`, the staff sheets).
- Respect safe areas; tab screens sit inside the shell's `Scaffold`.

## Designs versus the API

The designs are not a schema. Several mock-ups show fields the API does not
return (budgets, timelines, notes) or values it does not have (extra roles and
statuses). The backend wins: the UI is shaped to the real data, and the
difference is recorded ([ADR 0003](adr/0003-backend-enums-are-truth.md)).
