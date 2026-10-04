# Architecture

Clean Architecture with domain-driven features, built one feature at a time.

## Folder structure

```
lib/
  main.dart            composition root: orientation lock, ProviderScope, auth wiring
  app.dart             MaterialApp.router, theme, text-scale clamp
  core/                knows nothing about any feature
    constants/         AppConstants, AppAssets
    formatting/        AppFormatters (dates, money, phones, names, countdowns)
    navigation/        router, routes, redirect rules, role shells, session seams
    network/           ApiClient, endpoints, pagination, Dio providers
    sizing/            AppSizing
    storage/           SecureStore, PreferencesStore
    theme/             AppColors, AppTextStyles, AppTheme
    utils/             Result, error handling, Validators, MediaPicker, LinkOpener
  features/<name>/
    data/              datasources (IO, throw), models (DTOs), repository impls
    domain/            entities, repository interfaces, usecases (only with real logic)
    presentation/      screens, widgets, providers
  shared/              widgets, screens and extensions reused across features
test/                  mirrors lib/
docs/                  you are here
```

Current features: `auth`, `dashboard` (tracking lookup), `cases`, `staff`.

## The dependency rule

```
presentation  ──▶  domain  ◀──  data
```

- **Presentation depends on domain** — screens and providers see entities and
  repository interfaces, never models or datasources (wiring files excepted, see
  [Dependency injection](dependency-injection.md)).
- **Data implements domain** — `*RepositoryImpl` implements the interface,
  models extend entities.
- **Domain depends on nothing** but `core/` value types (`Result`, `AppRole`).
- **A feature never imports another feature.** Anything two features need moves
  to `core/` (non-visual) or `shared/` (visual).
- **`core/` never imports a feature** — with one deliberate exception: the
  router (`core/navigation/app_router.dart`) imports feature screens, because it
  is where screens are mounted.

The `dashboard` feature's `TrackingStatus` is a deliberate copy of the cases
feature's `CaseStatus` for exactly this reason — keep their values and pill
colours in step by hand.

## How a request flows

```
Widget ──watch──▶ Notifier ──▶ Repository (interface)
                                   │
                         RepositoryImpl ──▶ Datasource ──▶ ApiClient ──▶ Dio
                         catches, converts      throws        unwraps envelope
                         to Result<T>                         throws DioException
```

1. A **datasource** makes the call and throws on any failure.
2. The **repository implementation** is the only place that catches. It
   converts through `ErrorHandler.from` and returns `Ok(value)` or
   `Err(AppFailure)`.
3. A **notifier** unwraps the `Result` — in `build` with `unwrapOrThrow()`, so
   the failure becomes `AsyncError`; in a mutation by folding it.
4. A **widget** renders loading, data or `failure.message`.

See [Error handling](error-handling.md) for the full contract.

## Where cross-feature state lives

Some state is needed everywhere but owned by one feature — chiefly "who is
signed in". The rule is that core declares a provider with a safe default and
the owning feature supplies the real value at the composition root:

| Seam (in `core/`) | Default | Supplied by |
| --- | --- | --- |
| `sessionProvider` | signed out | `authOverrides` |
| `hasSeenOnboardingProvider` | `false` | `authOverrides` |
| `sessionRestoreProvider` | completes at once | `authOverrides` |
| `authTokenProvider` | no token | `authOverrides` |
| `unauthorizedHandlerProvider` | no-op | `authOverrides` |

`main.dart` passes `authOverrides` to the `ProviderScope`. Cases, staff and the
router read these seams and never import auth. See
[ADR 0007](adr/0007-auth-through-core-seams.md).

## Usecases

Only where they earn their place. A usecase that forwards one call from a
notifier to a repository is noise; none of the current features has one. Add
one when there is real orchestration — several repositories, or a rule that
must hold wherever the operation is triggered.

## Adding a feature

1. Read the entities off a real API response first — the designs are not a
   schema. Note anything undocumented.
2. Create `features/<name>/` with the three layers. Copy the Cases or Staff
   layering.
3. Add endpoint paths to `ApiEndpoints` and routes to `AppRoutes`.
4. Wire providers in `presentation/providers/<name>_providers.dart`.
5. Mirror every `lib/` file you test under `test/`.
6. If the data belongs to one user, `ref.watch(sessionProvider)` in the
   notifier's `build` (see [State management](state-management.md)).
7. Exercise every write against the live API before calling it done
   ([Testing](testing.md#verify-against-the-live-api)).
