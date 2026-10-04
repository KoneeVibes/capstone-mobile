# Accessibility

What the app does today, what to do in new code, and the known gaps. The app
has not had a screen-reader audit; treat this as a floor, not a certificate.

## In place

- **Text scaling is honoured within limits.** `app.dart` clamps the system text
  scale to 0.85–1.3, so large font settings enlarge text without breaking the
  approved layouts. Layouts must still work at 1.3.
- **Custom controls announce themselves.** The bottom-nav tabs, back buttons,
  text links and the one-time-code field wrap their visuals in `Semantics`
  (button / selected / text-field roles with labels).
- **Icon-only buttons have tooltips**, e.g. the show/hide password toggle, which
  screen readers read as the label.
- **Fields always have a name.** `AppTextField` shows its label above the field;
  with `showLabel: false` the label becomes the hint, so it is still announced.
- **Autofill hints** on email, name, phone, password and one-time-code fields
  let password managers and the system fill them.
- **Decorative images are excluded** from semantics (the auth photos);
  meaningful ones carry a label (the splash wordmark).
- **Errors are text**, not colour alone: a wrong code turns the boxes red
  *and* prints "Wrong code, please try again".
- **Portrait only** — a product decision ([ADR 0004](adr/0004-single-light-theme-portrait.md)),
  but note it as a restriction for users who mount their device.

## In new code

- Give every tappable thing a role and a label: prefer `IconButton(tooltip:)`,
  or wrap custom gestures in `Semantics(button: true, label: …)`.
- Keep tap targets at least 48 × 48 dp — pad small visuals rather than
  enlarging them.
- Never convey state by colour alone; pair it with text or an icon.
- Check the screen at text scale 1.3 and with TalkBack or VoiceOver before
  calling it done.
- Mark purely decorative images `excludeFromSemantics: true`.

## Known gaps

Measured against WCAG 2.1 AA, which asks 4.5:1 for normal text and 3:1 for large
text:

| Pair | Ratio | Status |
| --- | --- | --- |
| White button text on `primaryBright` | 3.68:1 | below AA for 16 px text |
| `primaryBright` links on `background` | 3.40:1 | below AA |
| `textTertiary` hints on white | 2.54:1 | below AA (placeholder text) |
| `textSecondary` on `background` | 4.47:1 | just below AA |
| `textSecondary` on white | 4.83:1 | passes |
| `primary` on white, either way round | 8.78:1 | passes |
| `textPrimary` on `background` | 18.17:1 | passes |

The first three come from the designs. Raising them is a design decision — flag
it with the designer rather than changing the tokens unilaterally. If changed,
`primary` (`#0B2FD6`) already passes and could carry button fills.

Also outstanding:

- Undersized tap targets: the square back buttons are 32 dp and the text links
  (`AuthLink`) about 36 dp tall.
- No focus-order or reading-order review on the longer forms (register).
- The splash and the shimmer skeletons are not announced as "loading".
- The bottom navigation's tabs announce their label, not their position
  ("tab 2 of 4").
