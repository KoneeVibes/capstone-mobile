# Dependency injection

Riverpod providers are the dependency-injection container. There is no
`get_it`, no service locator and no global singletons outside providers.

## The philosophy

- **Every dependency is a provider**, so every dependency can be overridden —
  in a test, or at the composition root.
- **Constructors take their collaborators.** `CasesRepositoryImpl(dataSource)`,
  `AuthRemoteDataSourceImpl(apiClient)`. Classes never reach for a provider
  themselves; only provider bodies and notifiers call `ref`.
- **Interfaces at the seams that matter.** Repositories always have an abstract
  interface in `domain/`. Datasources have one where a test needs to replace
  them. Platform plugins always do (below).

## Lifecycles

| Provider | Lives | Notes |
| --- | --- | --- |
| `dioProvider`, `apiClientProvider` | the app | one Dio, shared connections and interceptors |
| Datasource and repository providers | the app | rebuild only if a watched dependency changes |
| Notifiers holding user data | the app, reset per user | watch `sessionProvider` |
| Flow notifiers (sign-up, reset) | the app, memory only | cleared at the end of the flow |
| `otpCooldownProvider(email)` | the app, per email | one timer per email |

Nothing in the app is `autoDispose` today. The tab shell keeps screens alive,
and Riverpod 3 pauses providers nobody is listening to.

## Wiring files

Each feature has one file that builds its object graph:

```dart
// features/cases/presentation/providers/cases_providers.dart
final casesDataSourceProvider = Provider<CasesDataSource>(
  (ref) => CasesRemoteDataSourceImpl(
    ref.watch(apiClientProvider),
    resolveAssignees: ref.watch(sessionProvider)?.isStaff ?? false,
  ),
);

final casesRepositoryProvider = Provider<CasesRepository>(
  (ref) => CasesRepositoryImpl(ref.watch(casesDataSourceProvider)),
);
```

This file is the one place in `presentation/` allowed to import from `data/`.

## The composition root

`main.dart` is where features are plugged into core:

```dart
runApp(
  ProviderScope(overrides: authOverrides, child: const PropertyIntelApp()),
);
```

`authOverrides` replaces core's signed-out defaults with the real session, token
supplier and 401 handler. The token supplier and handler read the session
**lazily, inside their callbacks**. Watching it would rebuild Dio on every sign-in,
and would create a cycle, since the session's own repository uses Dio.

## Platform plugins sit behind interfaces

Features and tests never touch a platform channel directly:

| Wrapper (`core/`) | Wraps | Returns |
| --- | --- | --- |
| `MediaPicker` | `image_picker`, `file_picker` | `Result`; `Ok(null)` is a dismissal |
| `LinkOpener` | `url_launcher` | `Result` |
| `SecureStore` | `flutter_secure_storage` | throws on platform failure |
| `PreferencesStore` | `shared_preferences` | throws on platform failure |

Each has a provider (`secureStoreProvider`, …), so a test overrides it with a fake
rather than mocking a method channel.

## Testing with overrides

```dart
final container = ProviderContainer(
  overrides: [casesRepositoryProvider.overrideWithValue(mockRepository)],
);
addTearDown(container.dispose);
```

Override at the highest level that isolates what you test. For notifiers, that is
usually the repository. For auth, add `...authOverrides` so the seams behave as
they do in the app. See [Testing](testing.md).
