import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/navigation/app_session.dart';
import '../../domain/entities/recent_search.dart';

/// Successful lookups this session, newest first.
///
/// TODO(backend): in memory until recent searches have an endpoint.
class RecentSearchesNotifier extends Notifier<List<RecentSearch>> {
  static const int maxEntries = 5;

  @override
  List<RecentSearch> build() {
    ref.watch(sessionProvider);
    return const [];
  }

  void record(RecentSearch search) => state = [
    search,
    ...state.where((entry) => entry.trackingId != search.trackingId),
  ].take(maxEntries).toList(growable: false);
}

final recentSearchesProvider =
    NotifierProvider<RecentSearchesNotifier, List<RecentSearch>>(
      RecentSearchesNotifier.new,
    );
