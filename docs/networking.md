# Networking

All HTTP goes through `ApiClient` (`core/network/api_client.dart`), a thin
wrapper over one shared [dio](https://pub.dev/packages/dio) instance.

## Base URL

The host is a compile-time define, so no build hard-codes an environment:

```sh
flutter run --dart-define=API_BASE_URL=https://staging.example.com
```

Unset, it defaults to the shared development API. `/api/v1` is appended by
`ApiEndpoints.baseUrl`.

## Endpoints

Paths live in `ApiEndpoints`, never inline in a datasource:

```dart
static const String cases = '/case';               // singular: the API is /case
static String caseById(String id) => '$cases/$id';
```

## The envelope

The API answers `{status, message, data, meta?}`. `ApiClient`:

- **rejects anything but 2xx**, and also a 200 whose envelope says
  `status: "fail"`, by throwing a `DioException` that still carries the response
  — so `ErrorHandler` can read the server's message;
- **decodes `data`** with the decoder the datasource passes in;
- **keeps the raw body** on `ApiResponse.body`, for endpoints that put their
  payload beside `data`. Sign-in returns `{status, token}` with no `data` node.

**Assume nothing about an endpoint's envelope without checking a real
response.** `POST /staff` returns no `data`; sign-in returns `token` at the top
level; a list filter that matches nothing returns HTTP 404 with an envelope that
says `success`.

## Pagination

`ApiClient.getAllPages` (`core/network/api_pagination.dart`) walks
`meta.totalPages` and returns every item. Lists that filter and count on the
device use it, so nothing is silently cut off at page one
([ADR 0006](adr/0006-cases-fetched-whole.md)). The staff list pages in
the UI instead (infinite scroll on `meta`).

## Query lists

`BaseOptions.listFormat` is `ListFormat.multi`: `filter=a&filter=b`. Dio's
default sends `filter[]=a&filter[]=b`, which this API silently ignores — it
answers as though no filter had been sent.

## Authentication

`_AuthInterceptor` adds `Authorization: Bearer <token>` when
`authTokenProvider` supplies one, and calls `unauthorizedHandlerProvider` when a
request **that carried a token** comes back 401. A 401 without a token — a wrong
password at sign-in — is an ordinary failure and is left alone. Both providers
are filled in by the auth feature; see
[Navigation and auth](navigation-and-auth.md).

## Timeouts

30 s connect, 60 s send and receive (`AppConstants`). The API is hosted on a
free tier that sleeps when idle; the first request afterwards can take around
23 seconds. Do not "fix" a slow first call by lowering timeouts.

## Logging

`_LoggingInterceptor` is added only in debug builds and every branch checks
`kDebugMode`, so none of it can reach a release binary. It prints, per request:

- method, URL, headers, query and payload;
- status and body on success; status, error type and body on failure;
- multipart bodies as field and file **names**, never bytes.

`redactSecretsForLog` masks the value of any key **containing** `password`,
`token`, `authorization`, `secret` or `apikey`, case-insensitively, in headers
and bodies, nested or in lists. Matching fragments rather than exact names is
deliberate: exact names let `confirmPassword` through once. Check the log
whenever you add a request with a new payload shape.

## Files and links

Uploads use `FormData` through the same `ApiClient`. Picking files and opening
links go through `MediaPicker` and `LinkOpener` — see
[Dependency injection](dependency-injection.md#platform-plugins-sit-behind-interfaces).
