import '../../../../core/utils/error/error_handler.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/property_location.dart';
import '../../domain/entities/search_request.dart';
import '../../domain/repositories/property_search_repository.dart';
import '../datasources/property_search_remote_datasource.dart';

class PropertySearchRepositoryImpl implements PropertySearchRepository {
  const PropertySearchRepositoryImpl(this._source);

  final PropertySearchDataSource _source;

  @override
  Future<Result<List<PropertyLocation>>> fetchLocations() =>
      _guard(_source.fetchLocations);

  @override
  Future<Result<SubmittedSearch>> submit(SearchRequest request) =>
      _guard(() => _source.submit(request));

  @override
  Future<Result<Invoice>> fetchInvoice(String invoiceId) =>
      _guard(() => _source.fetchInvoice(invoiceId));

  static Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Ok(await action());
    } on Object catch (error, stackTrace) {
      return Err(ErrorHandler.from(error, stackTrace));
    }
  }
}
