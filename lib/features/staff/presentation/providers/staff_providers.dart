import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_provider.dart';
import '../../data/datasources/staff_remote_datasource.dart';
import '../../data/repositories/staff_repository_impl.dart';
import '../../domain/repositories/staff_repository.dart';

/// Wiring for the staff feature.
///
/// Tests override [staffRepositoryProvider] to run the notifiers against a
/// mock without touching the network.
final staffRemoteDataSourceProvider = Provider<StaffRemoteDataSource>(
  (ref) => StaffRemoteDataSourceImpl(ref.watch(apiClientProvider)),
);

final staffRepositoryProvider = Provider<StaffRepository>(
  (ref) => StaffRepositoryImpl(ref.watch(staffRemoteDataSourceProvider)),
);
