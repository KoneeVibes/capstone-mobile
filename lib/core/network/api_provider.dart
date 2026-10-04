import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';

/// Supplies the bearer token attached to every request.
///
/// Null by default; `authOverrides` (features/auth) reads it from the session
/// at the composition root, so nothing in the networking layer imports auth.
final authTokenProvider = Provider<TokenSupplier>((ref) {
  return () async => null;
});

/// What to do when a request that carried a token is answered 401. A no-op by
/// default; `authOverrides` ends the session.
final unauthorizedHandlerProvider = Provider<UnauthorizedHandler>((ref) {
  return () {};
});

/// The configured Dio instance. Single instance for the app so connections and
/// interceptors are shared.
final dioProvider = Provider<Dio>((ref) {
  final dio = ApiClient.createDio(
    tokenSupplier: ref.watch(authTokenProvider),
    onUnauthorized: ref.watch(unauthorizedHandlerProvider),
  );
  ref.onDispose(dio.close);
  return dio;
});

/// The client every datasource depends on.
final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(dioProvider)),
);
