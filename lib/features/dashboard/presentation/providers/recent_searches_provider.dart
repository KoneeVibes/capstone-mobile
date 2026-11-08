import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/navigation/app_session.dart';
import '../../domain/entities/recent_search.dart';
import 'dashboard_providers.dart';

/// How many recent searches the dashboard shows.
const int recentSearchesLimit = 5;

/// The user's newest tracking lookups, from their server-side search history.
/// Re-read after each lookup, since a signed-in lookup is what records one.
final recentSearchesProvider = FutureProvider.autoDispose<List<RecentSearch>>((
  ref,
) async {
  if (ref.watch(sessionProvider) == null) return untilSignedIn();
  final result = await ref
      .read(dashboardRepositoryProvider)
      .fetchRecentSearches(limit: recentSearchesLimit);
  return result.unwrapOrThrow();
});
