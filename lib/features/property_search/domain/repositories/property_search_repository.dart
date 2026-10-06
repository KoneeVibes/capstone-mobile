import '../../../../core/utils/result.dart';
import '../entities/invoice.dart';
import '../entities/property_location.dart';
import '../entities/search_request.dart';

abstract class PropertySearchRepository {
  /// Every location a search can be priced for.
  Future<Result<List<PropertyLocation>>> fetchLocations();

  /// Files the search as a case. It starts unpaid.
  Future<Result<SubmittedSearch>> submit(SearchRequest request);

  Future<Result<Invoice>> fetchInvoice(String invoiceId);
}
