# Coding standards

The lint rules enforce what they can; this page covers the rest. When a rule
here stops serving the project, change it — in a pull request that says why.

## Imports and style

- **Relative imports inside `lib/`** (`prefer_relative_imports`, a warning).
  Tests import the package.
- Single quotes, trailing commas, sorted directives — all linted.
- `flutter analyze` reports no issues before anything is merged.
- Format only the files you touched ([Tooling](tooling.md#formatting)).

## Naming

| Thing | Convention | Example |
| --- | --- | --- |
| Files | `snake_case.dart`, named after the main type | `auth_repository_impl.dart` |
| Repository interface / implementation | `XRepository` / `XRepositoryImpl` | `CasesRepository` |
| Datasource | `XRemoteDataSource(Impl)`, `XLocalDataSource` | `AuthRemoteDataSourceImpl` |
| Model extending an entity | `XModel` | `CaseModel` |
| Provider | `xProvider`; notifier `XNotifier` | `casesListProvider` |
| Shared widget | `App` prefix | `AppButton` |
| Feature-local widget | named for the feature | `CaseListTile`, `AuthPage` |
| Route name / path | `AppRoutes.xName` / `AppRoutes.xPath` | `loginName`, `loginPath` |
| Notifier mutations | a verb plus the noun — never `update` | `updateStaff` |

## Comments

- **Say why, not what.** The code says what. A comment earns its place by
  recording a reason a reader could not recover: an API quirk, a rejected
  alternative, a constraint.
- **Keep comments to a line or two in new code.** Longer rationale goes in an
  [ADR](adr/README.md) or the docs, linked from the code if needed.
- **Date what you verified live**: "verified live 4 Oct 2026" tells the next
  reader how much to trust it.

## Prefer asserts to comments for invariants

An invariant written as a comment is a hope; written as an `assert` it fails in
development the moment it is broken.

```dart
// Good: fails loudly in debug if the tabs and branches drift apart.
assert(
  tabs.length == navigationShell.route.branches.length,
  'Every shell branch needs exactly one tab, in the same order.',
);

// Bad: nothing checks it.
// Tab order must match the router's branch order.
```

Asserts are compiled out of release builds, so they cost nothing at runtime.
They do not replace validation of user or server input — that still returns a
`Result` or a validator message.

## Documenting shared code

Everything public in `lib/shared/` is reused by more than one feature, so it must
be understandable without reading its callers. `lib/shared/analysis_options.yaml`
turns on `public_member_api_docs` there. Each public widget documents:

- **its purpose** — the class doc, one line, then any "use this when" guidance;
- **its constructor** — what the caller must supply and any constraint;
- **each parameter** — what it does, and the default when that matters.

Features are not under the rule: their public API is small and read alongside
its callers. Document a feature's classes when the reason for them is not
obvious.

## Errors, state, UI

The contracts in [Error handling](error-handling.md),
[State management](state-management.md) and
[UI and design system](ui-and-design-system.md) are standards too. In short: no
raw exception reaches the UI, no literal colours or sizes in widgets, no
pass-through usecases, and features never import each other.

## Commits

[Conventional Commits](https://www.conventionalcommits.org): `feat(auth): …`,
`fix(cases): …`, `chore: …`. One feature or fix per commit. The body explains why.
