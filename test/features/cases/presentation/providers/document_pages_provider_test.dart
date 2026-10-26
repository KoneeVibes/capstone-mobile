import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propertyintelmobileapp/core/utils/document_preview.dart';
import 'package:propertyintelmobileapp/core/utils/error/app_failures.dart';
import 'package:propertyintelmobileapp/core/utils/error/async_value_x.dart';
import 'package:propertyintelmobileapp/features/cases/presentation/providers/document_pages_provider.dart';

const _url = 'https://x/plan.png';

/// Serves [bytes], or refuses with a 401 when [refuse] is set.
class _Backend implements DocumentPreviewBackend {
  _Backend({this.bytes, this.refuse = false});

  final Uint8List? bytes;
  final bool refuse;
  int downloads = 0;

  @override
  Future<Uint8List> download(String url) async {
    downloads++;
    if (refuse) {
      final options = RequestOptions(path: url);
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response<dynamic>(requestOptions: options, statusCode: 401),
      );
    }
    return bytes!;
  }

  @override
  Future<List<Uint8List>> renderPdf(Uint8List pdf, {required int width}) =>
      throw UnimplementedError();
}

void main() {
  ProviderContainer makeContainer(_Backend backend) {
    final container = ProviderContainer(
      overrides: [
        documentPreviewProvider.overrideWithValue(DocumentPreview(backend)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// Waits for the provider to settle, through a listener: awaiting `.future`
  /// on a provider whose build throws can hang (LESSONS).
  Future<AsyncValue<List<Uint8List>>> settle(
    ProviderContainer container,
  ) async {
    final sub = container.listen(documentPagesProvider(_url), (_, _) {});
    addTearDown(sub.close);
    for (var i = 0; i < 20 && sub.read().isLoading; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    return sub.read();
  }

  test('serves the drawn pages', () async {
    final page = Uint8List.fromList([7]);

    final value = await settle(makeContainer(_Backend(bytes: page)));

    expect(value.value, [page]);
  });

  test('a file the host refuses surfaces as an AppFailure, once', () async {
    final backend = _Backend(refuse: true);

    final value = await settle(makeContainer(backend));

    expect(value.failure, AppFailures.documentUnavailable);
    // Not retried behind the user's back.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(backend.downloads, 1);
  });
}
