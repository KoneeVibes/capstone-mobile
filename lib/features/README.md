# Features

One folder per feature, each self-contained:

```
<feature>/
  data/
    datasources/        remote (and local, where needed) IO — throws on failure
    models/             API DTOs, extend the domain entity
    repositories/       *_repository_impl.dart — catches, maps via ErrorHandler,
                        returns Result<T>
  domain/
    entities/           plain value objects (Equatable)
    repositories/       abstract interface the data layer implements
    usecases/           only where there is real logic to hold
  presentation/
    screens/
    widgets/
    providers/
```

Features do not import each other. Anything two features need belongs in
`core/` or `shared/`.
