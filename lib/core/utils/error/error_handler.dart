import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'app_failure.dart';
import 'failure_type.dart';

/// Converts any thrown object into an [AppFailure] carrying copy a user can act
/// on. This is the only place in the app allowed to inspect a raw exception.
///
/// The strategy for HTTP failures is documented-message-first: if the server
/// sent a presentable `message` we show it, otherwise we fall back to an
/// assumption derived from the status code, so an undocumented error still
/// tells the user roughly what went wrong.
abstract final class ErrorHandler {
  const ErrorHandler._();

  // Copy for failures that never carry a status code.
  static const String _networkMessage =
      'You appear to be offline. Check your connection and try again.';
  static const String _timeoutMessage =
      'The request took too long. Please try again.';
  static const String _cancelledMessage = 'The request was cancelled.';
  static const String _parsingMessage =
      'We received an unexpected response. Please try again.';
  static const String _unknownMessage =
      'Something went wrong. Please try again.';

  /// A server message longer than this is prose or a stack dump, not UI copy.
  static const int _maxDocumentedMessageLength = 200;

  /// Substrings that mark a server "message" as developer output rather than
  /// something a user should ever read.
  static const List<String> _leakMarkers = [
    'exception',
    'error:',
    'stack trace',
    '#0',
    'null check',
    "type '",
    '<html',
    'at java.',
    'traceback',
  ];

  /// Normalises [error] into an [AppFailure].
  ///
  /// Safe to call on a value that is already an [AppFailure] — it is returned
  /// unchanged, so passing an error through more than one layer cannot rewrite
  /// the message the user sees.
  static AppFailure from(Object error, [StackTrace? stackTrace]) {
    if (error is AppFailure) return error;

    final debug = _debugDetail(error, stackTrace);

    if (error is DioException) return _fromDio(error, debug);

    if (error is SocketException || error is HttpException) {
      return AppFailure(
        type: FailureType.network,
        message: _networkMessage,
        debugMessage: debug,
      );
    }

    if (error is FormatException || error is TypeError) {
      return AppFailure(
        type: FailureType.parsing,
        message: _parsingMessage,
        debugMessage: debug,
      );
    }

    return AppFailure(
      type: FailureType.unknown,
      message: _unknownMessage,
      debugMessage: debug,
    );
  }

  static AppFailure _fromDio(DioException error, String? debug) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return AppFailure(
          type: FailureType.timeout,
          message: _timeoutMessage,
          statusCode: error.response?.statusCode,
          debugMessage: debug,
        );

      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
        return AppFailure(
          type: FailureType.network,
          message: _networkMessage,
          debugMessage: debug,
        );

      case DioExceptionType.cancel:
        return AppFailure(
          type: FailureType.cancelled,
          message: _cancelledMessage,
          debugMessage: debug,
        );

      case DioExceptionType.badResponse:
        return _fromStatusCode(
          error.response?.statusCode,
          error.response?.data,
          debug,
        );

      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          return AppFailure(
            type: FailureType.network,
            message: _networkMessage,
            debugMessage: debug,
          );
        }
        // Some transports surface a real response under `unknown`; use it
        // rather than falling back to the generic message.
        if (error.response != null) {
          return _fromStatusCode(
            error.response?.statusCode,
            error.response?.data,
            debug,
          );
        }
        return AppFailure(
          type: FailureType.unknown,
          message: _unknownMessage,
          debugMessage: debug,
        );
    }
  }

  static AppFailure _fromStatusCode(int? code, Object? body, String? debug) {
    final (type, fallback) = classify(code);
    return AppFailure(
      type: type,
      message: documentedMessage(body) ?? fallback,
      statusCode: code,
      debugMessage: debug,
    );
  }

  /// Maps a status code to a failure type and the assumption we present when
  /// the server told us nothing useful.
  ///
  /// Visible for testing.
  @visibleForTesting
  static (FailureType, String) classify(int? code) {
    switch (code) {
      case 400:
        return (
          FailureType.badRequest,
          "Some of the details sent weren't valid. Please check and try again.",
        );
      case 401:
        return (
          FailureType.unauthorized,
          'Your session has expired. Please sign in again.',
        );
      case 403:
        return (
          FailureType.forbidden,
          "You don't have permission to do that.",
        );
      case 404:
        return (
          FailureType.notFound,
          "We couldn't find what you were looking for.",
        );
      case 408:
        return (FailureType.timeout, _timeoutMessage);
      case 409:
        return (
          FailureType.conflict,
          'That already exists. Please use different details.',
        );
      case 413:
        return (FailureType.badRequest, 'That file is too large to upload.');
      case 415:
        return (FailureType.badRequest, "That file type isn't supported.");
      case 422:
        return (
          FailureType.validation,
          "Some of the details sent weren't accepted. "
              'Please review and try again.',
        );
      case 429:
        return (
          FailureType.rateLimited,
          'Too many attempts. Please wait a moment and try again.',
        );
      case 502:
      case 503:
      case 504:
        return (
          FailureType.server,
          'The service is temporarily unavailable. Please try again shortly.',
        );
    }

    if (code == null) return (FailureType.unknown, _unknownMessage);
    if (code >= 500) {
      return (
        FailureType.server,
        'Something went wrong on our end. Please try again shortly.',
      );
    }
    if (code >= 400) {
      return (
        FailureType.badRequest,
        "We couldn't complete that request. Please try again.",
      );
    }
    return (FailureType.unknown, _unknownMessage);
  }

  /// Extracts a server-supplied message from an error body, but only when it
  /// reads like something written for a user.
  ///
  /// The API's documented error shape is `{"status": "fail", "message": "..."}`.
  /// Anything long, multi-line, or carrying developer output is rejected so the
  /// status-code assumption is used instead.
  ///
  /// Visible for testing.
  @visibleForTesting
  static String? documentedMessage(Object? body) {
    if (body is! Map) return null;

    final raw = body['message'];
    if (raw is! String) return null;

    final message = raw.trim();
    if (message.isEmpty) return null;
    if (message.length > _maxDocumentedMessageLength) return null;
    if (message.contains('\n')) return null;

    final lower = message.toLowerCase();
    if (_leakMarkers.any(lower.contains)) return null;

    return message;
  }

  /// Exception text, kept for debug builds only so release binaries cannot leak
  /// internals through a crash reporter or an accidental render.
  static String? _debugDetail(Object error, StackTrace? stackTrace) {
    if (!kDebugMode) return null;
    final buffer = StringBuffer(error.toString());
    if (stackTrace != null) {
      final firstFrame = stackTrace.toString().split('\n').first.trim();
      if (firstFrame.isNotEmpty) buffer.write(' | at $firstFrame');
    }
    return buffer.toString();
  }
}
