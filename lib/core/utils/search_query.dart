import '../constants/app_constants.dart';

/// [raw] as `GET /search` takes it — trimmed, capped at the API's limit — or
/// null when it is too short to send, which a screen reads as "not searching".
String? searchQueryFrom(String raw) {
  final query = raw.trim();
  if (query.length < AppConstants.searchMinLength) return null;
  return query.length > AppConstants.searchMaxLength
      ? query.substring(0, AppConstants.searchMaxLength)
      : query;
}
