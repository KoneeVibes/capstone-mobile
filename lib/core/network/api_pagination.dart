import '../constants/app_constants.dart';
import 'api_client.dart';

extension ApiClientPagination on ApiClient {
  /// Every row of a paginated list endpoint, walking `meta.totalPages`.
  ///
  /// Sequential, so a large set never opens a request per page at once.
  Future<List<T>> getAllPages<T>(
    String path,
    List<T> Function(Object? data) decoder, {
    Map<String, dynamic> query = const {},
  }) async {
    final items = <T>[];
    var page = 1;
    var totalPages = 1;

    do {
      final response = await get<List<T>>(
        path,
        queryParameters: {
          ...query,
          'page': page,
          'perPage': AppConstants.listWalkPageSize,
        },
        decoder: decoder,
      );
      items.addAll(response.data);
      totalPages = response.meta?.totalPages ?? 1;
      page++;
    } while (page <= totalPages);

    return items;
  }
}
