import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/navigation/app_session.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/utils/error/app_failure.dart';
import '../../domain/entities/staff.dart';
import 'staff_providers.dart';

/// Everything the list screen renders.
class StaffListState extends Equatable {
  const StaffListState({
    this.items = const [],
    this.meta,
    this.isLoadingMore = false,
    this.loadMoreFailure,
  });

  final List<Staff> items;
  final PageMeta? meta;
  final bool isLoadingMore;

  /// Set when fetching the *next* page failed.
  ///
  /// Kept separate from the provider's own error state so a failed page two
  /// does not wipe out the rows already on screen — the list stays usable and
  /// shows an inline retry instead.
  final AppFailure? loadMoreFailure;

  bool get hasMore => meta?.hasNextPage ?? false;

  bool get isEmpty => items.isEmpty;

  StaffListState copyWith({
    List<Staff>? items,
    PageMeta? meta,
    bool? isLoadingMore,
    AppFailure? loadMoreFailure,
    bool clearLoadMoreFailure = false,
  }) => StaffListState(
    items: items ?? this.items,
    meta: meta ?? this.meta,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    loadMoreFailure: clearLoadMoreFailure
        ? null
        : loadMoreFailure ?? this.loadMoreFailure,
  );

  @override
  List<Object?> get props => [items, meta, isLoadingMore, loadMoreFailure];
}

/// The paginated staff list.
class StaffListNotifier extends AsyncNotifier<StaffListState> {
  @override
  Future<StaffListState> build() {
    ref.watch(sessionProvider);
    return _loadFirstPage();
  }

  Future<StaffListState> _loadFirstPage() async {
    final result = await ref
        .read(staffRepositoryProvider)
        .fetchStaff(page: 1, perPage: AppConstants.defaultPageSize);

    // Throws the AppFailure, which Riverpod stores as AsyncValue.error. The UI
    // reads it back through AsyncValueFailureX.failure, so it can only ever be
    // an AppFailure — never a raw exception.
    final page = result.unwrapOrThrow();
    return StaffListState(items: page.items, meta: page.meta);
  }

  /// Appends the next page. Safe to call repeatedly while scrolling.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null ||
        current.isLoadingMore ||
        !current.hasMore ||
        state.isLoading) {
      return;
    }

    state = AsyncData(
      current.copyWith(isLoadingMore: true, clearLoadMoreFailure: true),
    );

    final result = await ref
        .read(staffRepositoryProvider)
        .fetchStaff(
          page: current.meta!.nextPage,
          perPage: AppConstants.defaultPageSize,
        );

    state = AsyncData(
      result.fold(
        onOk: (page) => StaffListState(
          items: [...current.items, ...page.items],
          meta: page.meta ?? current.meta,
        ),
        onErr: (failure) =>
            current.copyWith(isLoadingMore: false, loadMoreFailure: failure),
      ),
    );
  }

  /// Reloads from page one. Backs pull-to-refresh and the error-state retry.
  Future<void> refresh() async {
    state = await AsyncValue.guard(_loadFirstPage);
  }
}

final staffListProvider =
    AsyncNotifierProvider<StaffListNotifier, StaffListState>(
      StaffListNotifier.new,
    );
