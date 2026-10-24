import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfx/pdfx.dart';

import '../constants/app_constants.dart';
import 'error/app_failures.dart';
import 'error/error_handler.dart';
import 'result.dart';

/// The two kinds of file the app can draw.
enum DocumentKind { pdf, image }

/// The network and platform work behind [DocumentPreview], separated so tests
/// need neither, as `LinkLauncherBackend` does for opening links.
abstract class DocumentPreviewBackend {
  /// The file's bytes. Throws `DioException` on any failure.
  Future<Uint8List> download(String url);

  /// Every page of [pdf], top to bottom, as a PNG [width] pixels wide.
  Future<List<Uint8List>> renderPdf(Uint8List pdf, {required int width});
}

/// Draws a document in the app, page by page, so it can be read in place.
///
/// Features call this, never pdfx (ADR 0009). Returns a [Result]: a file that
/// will not load is an ordinary outcome, not an exception for a widget.
class DocumentPreview {
  const DocumentPreview(this._backend);

  final DocumentPreviewBackend _backend;

  /// What [url] holds, from its extension; null for a type the app cannot draw.
  static DocumentKind? kindOf(String url) {
    final path = Uri.tryParse(url)?.path ?? url;
    final name = path.split('/').last;
    final dot = name.lastIndexOf('.');
    final extension = dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
    if (extension == 'pdf') return DocumentKind.pdf;
    if (AppConstants.allowedImageExtensions.contains(extension)) {
      return DocumentKind.image;
    }
    return null;
  }

  /// [url]'s pages as images: each page of a PDF, or an image as its one page.
  Future<Result<List<Uint8List>>> pagesOf(String url) async {
    final kind = kindOf(url);
    if (kind == null) return const Err(AppFailures.documentUnsupported);

    final Uint8List bytes;
    try {
      bytes = await _backend.download(url);
    } on DioException catch (error, stackTrace) {
      // The host answered, and refused. That is about the file, not the
      // session, which is what ErrorHandler would make of a 401.
      if (error.response != null) {
        return const Err(AppFailures.documentUnavailable);
      }
      return Err(ErrorHandler.from(error, stackTrace));
    }

    if (kind == DocumentKind.image) return Ok([bytes]);
    try {
      final pages = await _backend.renderPdf(
        bytes,
        width: AppConstants.documentPageWidth,
      );
      return pages.isEmpty
          ? const Err(AppFailures.documentUnavailable)
          : Ok(pages);
    } on Object {
      // A PlatformException: the bytes were not a PDF the renderer could read.
      return const Err(AppFailures.documentUnavailable);
    }
  }
}

/// Downloads with a plain [Dio], never `ApiClient`: these files live on a
/// third-party host, which must not be sent the session's bearer token.
class PdfxDocumentPreviewBackend implements DocumentPreviewBackend {
  PdfxDocumentPreviewBackend([Dio? dio])
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: AppConstants.connectTimeout,
              receiveTimeout: AppConstants.receiveTimeout,
            ),
          );

  final Dio _dio;

  @override
  Future<Uint8List> download(String url) async {
    final response = await _dio.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data ?? const []);
  }

  @override
  Future<List<Uint8List>> renderPdf(Uint8List pdf, {required int width}) async {
    final document = await PdfDocument.openData(pdf);
    try {
      final pages = <Uint8List>[];
      // One page open at a time: Android's renderer refuses parallel pages.
      for (var number = 1; number <= document.pagesCount; number++) {
        final page = await document.getPage(number);
        try {
          final image = await page.render(
            width: width.toDouble(),
            height: width * page.height / page.width,
            format: PdfPageImageFormat.png,
            backgroundColor: '#FFFFFF',
          );
          if (image != null) pages.add(image.bytes);
        } finally {
          await page.close();
        }
      }
      return pages;
    } finally {
      await document.close();
    }
  }
}

/// Override this in tests to draw documents without network or platform.
final documentPreviewProvider = Provider<DocumentPreview>(
  (ref) => DocumentPreview(PdfxDocumentPreviewBackend()),
);
