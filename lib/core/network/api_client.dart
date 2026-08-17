import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import 'api_endpoints.dart';
import 'api_response.dart';

/// Field names whose values must never be written to a log.
///
/// This is not hypothetical: `DELETE /api/v1/staff/{id}` returns the account's
/// bcrypt password hash in its response body, which would otherwise be printed
/// to logcat verbatim by the debug logger.
const Set<String> _secretLogKeys = {
  'password',
  'passwordhash',
  'token',
  'accesstoken',
  'refreshtoken',
  'authorization',
  'secret',
  'apikey',
};

/// Recursively replaces secret values with `***`, leaving the surrounding
/// structure intact so the log still shows the response's shape.
///
/// Visible for testing.
@visibleForTesting
Object? redactSecretsForLog(Object? value) {
  if (value is Map) {
    return <String, Object?>{
      for (final entry in value.entries)
        '${entry.key}':
            _secretLogKeys.contains(entry.key.toString().toLowerCase())
            ? '***'
            : redactSecretsForLog(entry.value),
    };
  }
  if (value is List) return value.map(redactSecretsForLog).toList();
  return value;
}

/// Supplies the bearer token for outgoing requests.
///
/// Returns null while signed out. Auth is not built yet, so the default
/// implementation always returns null; swapping in secure storage later needs
/// no change to [ApiClient].
typedef TokenSupplier = Future<String?> Function();

/// Thin wrapper over Dio that unwraps the API's `{status, message, data, meta}`
/// envelope and leaves error mapping to `ErrorHandler`.
///
/// Methods throw [DioException] on failure; repository implementations catch at
/// their boundary and convert. That keeps exactly one place in the app that
/// interprets a raw error.
class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  /// Exposed for interceptor setup and testing.
  Dio get dio => _dio;

  /// Builds a configured Dio instance.
  static Dio createDio({TokenSupplier? tokenSupplier}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        sendTimeout: AppConstants.sendTimeout,
        responseType: ResponseType.json,
        headers: const {'Accept': 'application/json'},
        // Only 2xx is a success. Everything else becomes a DioException that
        // still carries the response, so the logging interceptor reports it as
        // a failure and ErrorHandler can read the server's documented message.
        validateStatus: (status) =>
            status != null && status >= 200 && status < 300,
      ),
    );

    dio.interceptors.add(_AuthInterceptor(tokenSupplier));
    if (kDebugMode) dio.interceptors.add(_LoggingInterceptor());

    return dio;
  }

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(Object? data)? decoder,
    CancelToken? cancelToken,
  }) => _send<T>(
    path,
    method: 'GET',
    queryParameters: queryParameters,
    decoder: decoder,
    cancelToken: cancelToken,
  );

  Future<ApiResponse<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    T Function(Object? data)? decoder,
    CancelToken? cancelToken,
  }) => _send<T>(
    path,
    method: 'POST',
    data: data,
    queryParameters: queryParameters,
    decoder: decoder,
    cancelToken: cancelToken,
  );

  Future<ApiResponse<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    T Function(Object? data)? decoder,
    CancelToken? cancelToken,
  }) => _send<T>(
    path,
    method: 'PUT',
    data: data,
    queryParameters: queryParameters,
    decoder: decoder,
    cancelToken: cancelToken,
  );

  Future<ApiResponse<T>> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    T Function(Object? data)? decoder,
    CancelToken? cancelToken,
  }) => _send<T>(
    path,
    method: 'PATCH',
    data: data,
    queryParameters: queryParameters,
    decoder: decoder,
    cancelToken: cancelToken,
  );

  Future<ApiResponse<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    T Function(Object? data)? decoder,
    CancelToken? cancelToken,
  }) => _send<T>(
    path,
    method: 'DELETE',
    data: data,
    queryParameters: queryParameters,
    decoder: decoder,
    cancelToken: cancelToken,
  );

  Future<ApiResponse<T>> _send<T>(
    String path, {
    required String method,
    Object? data,
    Map<String, dynamic>? queryParameters,
    T Function(Object? data)? decoder,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.request<dynamic>(
      path,
      data: data,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      options: Options(method: method),
    );
    return _unwrap<T>(response, decoder);
  }

  /// Validates the envelope before decoding.
  ///
  /// Dio already rejects non-2xx responses, so in practice this catches a body
  /// that is not a JSON object and a 200 whose envelope says `status: "fail"`.
  /// The status-code check is kept as a backstop in case `validateStatus` is
  /// ever relaxed. Every rejection is a [DioException] carrying the response, so
  /// `ErrorHandler` can read the server's documented `message` and fall back to
  /// the status code otherwise.
  ApiResponse<T> _unwrap<T>(
    Response<dynamic> response,
    T Function(Object? data)? decoder,
  ) {
    final body = response.data;
    final statusCode = response.statusCode ?? 0;

    if (body is! Map<String, dynamic>) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        error: 'Expected a JSON object envelope, received '
            '${body.runtimeType}.',
      );
    }

    final envelopeStatus = (body['status'] as String? ?? '').toLowerCase();
    if (statusCode < 200 || statusCode >= 300 || envelopeStatus != 'success') {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
      );
    }

    return ApiResponse<T>.fromJson(body, decoder: decoder);
  }
}

/// Attaches the bearer token when one is available.
class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._tokenSupplier);

  final TokenSupplier? _tokenSupplier;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenSupplier?.call();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

/// Debug-only request and response logging.
///
/// Every branch is guarded by [kDebugMode] and the interceptor is only added to
/// Dio in debug builds, so nothing here can reach a release binary. Uses
/// [debugPrint] to avoid logcat's per-line truncation.
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('┌─ REQUEST ${options.method} ${options.uri}');
      debugPrint('│ headers: ${options.headers}');
      if (options.queryParameters.isNotEmpty) {
        debugPrint('│ query: ${options.queryParameters}');
      }
      debugPrint('│ payload: ${_truncate(_describeBody(options.data))}');
      debugPrint('└─');
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (kDebugMode) {
      debugPrint(
        '┌─ RESPONSE ${response.statusCode} '
        '${response.requestOptions.method} ${response.requestOptions.uri}',
      );
      debugPrint('│ body: ${_truncate(_describeBody(response.data))}');
      debugPrint('└─');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        '┌─ FAILED ${err.response?.statusCode ?? '-'} '
        '${err.requestOptions.method} ${err.requestOptions.uri}',
      );
      debugPrint('│ type: ${err.type.name}');
      debugPrint('│ error: ${_describeError(err)}');
      debugPrint('│ body: ${_truncate(_describeBody(err.response?.data))}');
      debugPrint('└─');
    }
    handler.next(err);
  }

  /// First line of the underlying error. Dio's default `message` runs to
  /// several paragraphs of guidance, which buries the rest of the log.
  static String _describeError(DioException err) {
    final detail = err.error?.toString() ?? err.message ?? '-';
    return _truncate(detail.split('\n').first.trim());
  }

  /// Renders a body for the log. Multipart uploads are described by field and
  /// file name only — never the bytes.
  static String _describeBody(Object? data) {
    if (data == null) return 'null';

    if (data is FormData) {
      final fields = data.fields.map((e) => '${e.key}: ${e.value}').join(', ');
      final files = data.files
          .map((e) => '${e.key}: ${e.value.filename ?? '<bytes>'}')
          .join(', ');
      return 'FormData(fields: {$fields}, files: {$files})';
    }

    try {
      return jsonEncode(redactSecretsForLog(data));
    } on Object {
      return data.toString();
    }
  }

  static String _truncate(String value) {
    if (value.length <= AppConstants.maxLoggedBodyLength) return value;
    return '${value.substring(0, AppConstants.maxLoggedBodyLength)}'
        '… (${value.length} chars total)';
  }
}
