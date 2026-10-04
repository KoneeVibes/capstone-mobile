import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_provider.dart';
import '../../../../core/storage/preferences_store.dart';
import '../../../../core/storage/secure_store.dart';
import '../../data/datasources/auth_local_datasource.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';

/// Wiring for the auth feature. Tests override [authRepositoryProvider].

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSourceImpl(ref.watch(apiClientProvider)),
);

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>(
  (ref) => AuthLocalDataSource(
    ref.watch(secureStoreProvider),
    ref.watch(preferencesStoreProvider),
  ),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    ref.watch(authRemoteDataSourceProvider),
    ref.watch(authLocalDataSourceProvider),
  ),
);
