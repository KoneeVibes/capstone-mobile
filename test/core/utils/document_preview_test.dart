import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propertyintelmobileapp/core/constants/app_constants.dart';
import 'package:propertyintelmobileapp/core/utils/document_preview.dart';
import 'package:propertyintelmobileapp/core/utils/error/app_failures.dart';
import 'package:propertyintelmobileapp/core/utils/error/failure_type.dart';

class FakeBackend implements DocumentPreviewBackend {
  FakeBackend({this.bytes, this.downloadError, this.pages, this.renderError});

  final Uint8List? bytes;
  final Object? downloadError;
  final List<Uint8List>? pages;
  final Object? renderError;

  final downloads = <String>[];
  final renderWidths = <int>[];

  @override
  Future<Uint8List> download(String url) async {
    downloads.add(url);
    if (downloadError != null) throw downloadError!;
    return bytes ?? Uint8List(0);
  }

  @override
  Future<List<Uint8List>> renderPdf(Uint8List pdf, {required int width}) async {
    renderWidths.add(width);
    if (renderError != null) throw renderError!;
    return pages ?? const [];
  }
}

/// Records each request and answers with three bytes.
class RecordingAdapter implements HttpClientAdapter {
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    return ResponseBody.fromBytes([1, 2, 3], 200);
  }

  @override
  void close({bool force = false}) {}
}

DioException _refused(int statusCode) {
  final options = RequestOptions(path: 'https://files.example/a.pdf');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(
      requestOptions: options,
      statusCode: statusCode,
    ),
  );
}

final _pdf = Uint8List.fromList([37, 80, 68, 70]);
final _page1 = Uint8List.fromList([1]);
final _page2 = Uint8List.fromList([2]);

void main() {
  group('kindOf', () {
    test('reads the extension, ignoring case and query', () {
      expect(
        DocumentPreview.kindOf('https://x/case%20report/a.PDF?v=2'),
        DocumentKind.pdf,
      );
      for (final name in ['a.png', 'a.jpg', 'a.jpeg']) {
        expect(DocumentPreview.kindOf('https://x/$name'), DocumentKind.image);
      }
    });

    test('is null for a type the app cannot draw', () {
      expect(DocumentPreview.kindOf('https://x/a.docx'), isNull);
      expect(DocumentPreview.kindOf('https://x/report'), isNull);
    });
  });

  group('pagesOf', () {
    test('draws every page of a PDF at the reading width', () async {
      final backend = FakeBackend(bytes: _pdf, pages: [_page1, _page2]);

      final result = await DocumentPreview(
        backend,
      ).pagesOf('https://x/report.pdf');

      expect(result.valueOrNull, [_page1, _page2]);
      expect(backend.renderWidths, [AppConstants.documentPageWidth]);
    });

    test('an image is its own one page, with nothing rendered', () async {
      final backend = FakeBackend(bytes: _page1);

      final result = await DocumentPreview(
        backend,
      ).pagesOf('https://x/photo.png');

      expect(result.valueOrNull, [_page1]);
      expect(backend.renderWidths, isEmpty);
    });

    test(
      'a refusal from the host is about the file, not the session',
      () async {
        // A 401 through ErrorHandler would read "Your session has expired".
        final result = await DocumentPreview(
          FakeBackend(downloadError: _refused(401)),
        ).pagesOf('https://x/report.pdf');

        expect(result.failureOrNull, AppFailures.documentUnavailable);
        expect(result.failureOrNull!.isRetryable, isFalse);
        expect(result.failureOrNull!.requiresReauthentication, isFalse);
      },
    );

    test('a dropped connection is a retryable network failure', () async {
      final result = await DocumentPreview(
        FakeBackend(
          downloadError: DioException(
            requestOptions: RequestOptions(path: 'https://x/report.pdf'),
            type: DioExceptionType.connectionError,
          ),
        ),
      ).pagesOf('https://x/report.pdf');

      expect(result.failureOrNull!.type, FailureType.network);
      expect(result.failureOrNull!.isRetryable, isTrue);
    });

    test('a type the app cannot draw is never downloaded', () async {
      final backend = FakeBackend();

      final result = await DocumentPreview(
        backend,
      ).pagesOf('https://x/report.docx');

      expect(result.failureOrNull, AppFailures.documentUnsupported);
      expect(backend.downloads, isEmpty);
    });

    test('a PDF the renderer cannot read, or with no pages, fails', () async {
      for (final backend in [
        FakeBackend(bytes: _pdf, renderError: Exception('not a pdf')),
        FakeBackend(bytes: _pdf, pages: const []),
      ]) {
        final result = await DocumentPreview(
          backend,
        ).pagesOf('https://x/report.pdf');
        expect(result.failureOrNull, AppFailures.documentUnavailable);
      }
    });
  });

  group('PdfxDocumentPreviewBackend.download', () {
    test('fetches the bytes without the session token', () async {
      final adapter = RecordingAdapter();
      final dio = Dio()..httpClientAdapter = adapter;

      final bytes = await PdfxDocumentPreviewBackend(
        dio,
      ).download('https://files.example/report.pdf');

      expect(bytes, [1, 2, 3]);
      final headers = adapter.last!.headers.keys.map((k) => k.toLowerCase());
      expect(headers, isNot(contains('authorization')));
    });
  });
}
