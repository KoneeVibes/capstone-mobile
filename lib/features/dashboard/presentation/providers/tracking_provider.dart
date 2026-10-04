import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/formatting/app_formatters.dart';
import '../../../../core/navigation/app_session.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/entities/recent_search.dart';
import '../../domain/entities/tracked_case.dart';
import 'dashboard_providers.dart';
import 'recent_searches_provider.dart';

/// The dashboard's lookup. Null means idle.
///
/// Errors are set, not thrown from `build`, so Riverpod never auto-retries a 404.
class TrackingNotifier extends AsyncNotifier<TrackedCase?> {
  /// Bumped by every lookup and [clear], so a stale response is dropped.
  int _generation = 0;

  @override
  FutureOr<TrackedCase?> build() {
    ref.watch(sessionProvider);
    return null;
  }

  Future<void> track(String input) async {
    if (Validators.trackingId(input) != null || state.isLoading) return;

    final generation = ++_generation;
    state = const AsyncLoading<TrackedCase?>();

    final result = await ref
        .read(dashboardRepositoryProvider)
        .trackCase(AppFormatters.trackingId(input));
    if (generation != _generation) return;

    result.fold(
      onOk: (value) {
        state = AsyncData<TrackedCase?>(value);
        ref
            .read(recentSearchesProvider.notifier)
            .record(RecentSearch.fromTracked(value));
      },
      onErr: (failure) =>
          state = AsyncError<TrackedCase?>(failure, StackTrace.current),
    );
  }

  void clear() {
    _generation++;
    state = const AsyncData<TrackedCase?>(null);
  }
}

final trackingProvider = AsyncNotifierProvider<TrackingNotifier, TrackedCase?>(
  TrackingNotifier.new,
);
