import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_provider.dart';
import '../../data/datasources/property_search_remote_datasource.dart';
import '../../data/repositories/property_search_repository_impl.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/property_location.dart';
import '../../domain/repositories/property_search_repository.dart';

final propertySearchDataSourceProvider = Provider<PropertySearchDataSource>(
  (ref) => PropertySearchRemoteDataSourceImpl(ref.watch(apiClientProvider)),
);

final propertySearchRepositoryProvider = Provider<PropertySearchRepository>(
  (ref) =>
      PropertySearchRepositoryImpl(ref.watch(propertySearchDataSourceProvider)),
);

/// The priced locations. Not per-user, so it outlives a sign-out.
final propertyLocationsProvider = FutureProvider<List<PropertyLocation>>((
  ref,
) async {
  final result = await ref
      .watch(propertySearchRepositoryProvider)
      .fetchLocations();
  return result.unwrapOrThrow();
});

/// A new case's invoice, by id. Dropped when its screen closes, so coming back
/// later reads the current status.
final invoiceProvider = FutureProvider.autoDispose.family<Invoice, String>((
  ref,
  invoiceId,
) async {
  final result = await ref
      .watch(propertySearchRepositoryProvider)
      .fetchInvoice(invoiceId);
  return result.unwrapOrThrow();
});
