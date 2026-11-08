import '../../../../core/constants/app_constants.dart';
import '../../../../core/formatting/app_formatters.dart';
import '../../../../shared/extensions/string_extensions.dart';
import '../../domain/entities/recent_search.dart';

/// Wire format for [RecentSearch]: a `GET /search/history` record.
class RecentSearchModel extends RecentSearch {
  const RecentSearchModel({
    required super.id,
    required super.trackingId,
    super.searchedAt,
  });

  factory RecentSearchModel.fromJson(Map<String, dynamic> json) =>
      RecentSearchModel(
        id: _string(json['id']) ?? '',
        trackingId: AppFormatters.trackingId(_string(json['query'])),
        searchedAt: AppFormatters.parseIso(_string(json['updatedAt'])),
      );

  /// Tracking IDs only, newest first, each once. The history also holds the
  /// website's free-text `/search` queries, which the lookup cannot reopen.
  static List<RecentSearch> listFromJson(Object? data) {
    if (data is! List) return const [];
    final seen = <String>{};
    return data
        .whereType<Map<String, dynamic>>()
        .map(RecentSearchModel.fromJson)
        .where(
          (search) =>
              AppConstants.trackingIdPattern.hasMatch(search.trackingId) &&
              seen.add(search.trackingId),
        )
        .toList(growable: false);
  }

  static String? _string(Object? value) {
    if (value is! String) return null;
    return value.nullIfBlank;
  }
}
