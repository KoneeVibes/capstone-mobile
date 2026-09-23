import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:propertyintelmobileapp/core/network/api_client.dart';
import 'package:propertyintelmobileapp/core/network/api_pagination.dart';
import 'package:propertyintelmobileapp/core/network/api_response.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient client;

  setUp(() => client = MockApiClient());

  void stubPages(Map<int, List<String>> pages) {
    when(
      () => client.get<List<String>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
        decoder: any(named: 'decoder'),
      ),
    ).thenAnswer((invocation) async {
      final query =
          invocation.namedArguments[#queryParameters] as Map<String, dynamic>;
      final page = query['page'] as int;
      return ApiResponse<List<String>>(
        status: 'success',
        message: 'success',
        data: pages[page] ?? const [],
        meta: PageMeta(
          page: page,
          perPage: 100,
          total: 0,
          totalPages: pages.length,
        ),
      );
    });
  }

  List<String> decode(Object? data) => const [];

  test('walks every page in order', () async {
    stubPages({
      1: ['a', 'b'],
      2: ['c'],
    });

    final rows = await client.getAllPages<String>('/case', decode);

    expect(rows, ['a', 'b', 'c']);
  });

  test('sends the query alongside the page and page size', () async {
    stubPages({1: const []});

    await client.getAllPages<String>(
      '/case',
      decode,
      query: const {'filter': 'closed'},
    );

    final query =
        verify(
              () => client.get<List<String>>(
                '/case',
                queryParameters: captureAny(named: 'queryParameters'),
                decoder: any(named: 'decoder'),
              ),
            ).captured.single
            as Map<String, dynamic>;
    expect(query, {'filter': 'closed', 'page': 1, 'perPage': 100});
  });
}
