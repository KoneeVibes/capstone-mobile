import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/property_location.dart';
import '../../domain/entities/search_request.dart';
import '../models/invoice_model.dart';
import '../models/property_location_model.dart';
import '../models/search_request_model.dart';

/// Network access for property searches. Throws; the repository converts.
///
/// All three endpoints are public — guests use them from the website — but
/// the client still sends the session's token, so a signed-in user's case is
/// filed as theirs.
abstract class PropertySearchDataSource {
  Future<List<PropertyLocation>> fetchLocations();

  Future<SubmittedSearch> submit(SearchRequest request);

  Future<Invoice> fetchInvoice(String invoiceId);
}

class PropertySearchRemoteDataSourceImpl implements PropertySearchDataSource {
  const PropertySearchRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<List<PropertyLocation>> fetchLocations() async {
    final response = await _client.get<List<PropertyLocation>>(
      ApiEndpoints.locations,
      decoder: PropertyLocationModel.listFromJson,
    );
    return response.data;
  }

  @override
  Future<SubmittedSearch> submit(SearchRequest request) async {
    final response = await _client.post<SubmittedSearch>(
      ApiEndpoints.cases,
      data: await SearchRequestModel.formDataFrom(request),
      decoder: SearchRequestModel.submittedFromData,
    );
    return response.data;
  }

  @override
  Future<Invoice> fetchInvoice(String invoiceId) async {
    final response = await _client.get<Invoice>(
      ApiEndpoints.invoiceById(invoiceId),
      decoder: InvoiceModel.fromData,
    );
    return response.data;
  }
}
