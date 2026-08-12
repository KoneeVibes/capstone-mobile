import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';

/// Supplies the bearer token attached to every request.
///
/// Auth is not built yet, so this returns null and no `Authorization` header is
/// sent. When auth lands, override this provider to read from secure storage —
/// nothing else in the networking layer has to change.
final authTokenProvider = Provider<TokenSupplier>((ref) {
  return () async => null;
});

/// The configured Dio instance. Single instance for the app so connections and
/// interceptors are shared.
final dioProvider = Provider<Dio>((ref) {
  final dio = ApiClient.createDio(tokenSupplier: ref.watch(authTokenProvider));
  ref.onDispose(dio.close);
  return dio;
});

/// The client every datasource depends on.
final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(dioProvider)),
);
