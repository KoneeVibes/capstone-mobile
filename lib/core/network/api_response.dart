import 'package:equatable/equatable.dart';

/// Pagination block returned alongside list responses.
class PageMeta extends Equatable {
  const PageMeta({
    required this.page,
    required this.perPage,
    required this.total,
    required this.totalPages,
  });

  factory PageMeta.fromJson(Map<String, dynamic> json) => PageMeta(
    page: _asInt(json['page']) ?? 1,
    perPage: _asInt(json['perPage']) ?? 0,
    total: _asInt(json['total']) ?? 0,
    totalPages: _asInt(json['totalPages']) ?? 1,
  );

  final int page;
  final int perPage;
  final int total;
  final int totalPages;

  /// Whether another page exists after this one. Drives infinite scroll.
  bool get hasNextPage => page < totalPages;

  int get nextPage => page + 1;

  static int? _asInt(Object? value) => switch (value) {
    final int v => v,
    final num v => v.toInt(),
    final String v => int.tryParse(v),
    _ => null,
  };

  @override
  List<Object?> get props => [page, perPage, total, totalPages];
}

/// The API's response envelope: `{status, message, data, meta?}`.
///
/// [T] is whatever the caller's decoder produced from `data`.
class ApiResponse<T> extends Equatable {
  const ApiResponse({
    required this.status,
    required this.message,
    required this.data,
    this.meta,
  });

  /// Builds an envelope from a decoded JSON body.
  ///
  /// [decoder] converts the raw `data` node. When omitted, `data` is handed
  /// back untouched and [T] must accommodate it.
  factory ApiResponse.fromJson(
    Map<String, dynamic> json, {
    T Function(Object? data)? decoder,
  }) {
    final rawMeta = json['meta'];
    return ApiResponse<T>(
      status: json['status'] as String? ?? '',
      message: json['message'] as String? ?? '',
      data: decoder != null ? decoder(json['data']) : json['data'] as T,
      meta: rawMeta is Map<String, dynamic> ? PageMeta.fromJson(rawMeta) : null,
    );
  }

  /// `success` on a good response, `fail` on a documented error.
  final String status;

  final String message;

  final T data;

  /// Present on paginated list responses only.
  final PageMeta? meta;

  bool get isSuccess => status.toLowerCase() == 'success';

  @override
  List<Object?> get props => [status, message, data, meta];
}
