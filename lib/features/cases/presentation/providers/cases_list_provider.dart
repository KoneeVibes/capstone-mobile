import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/navigation/app_session.dart';
import '../../../../core/session/cases_changed.dart';
import '../../domain/entities/case.dart';
import '../../domain/entities/case_filter.dart';
import 'cases_providers.dart';

/// Everything the list screen renders.
///
/// Holds every case and filters in [visible] rather than storing two lists, so
/// the `2 of 5 cases` footer always has both numbers to hand and switching a
/// tab costs no request.
class CasesListState extends Equatable {
  const CasesListState({this.items = const [], this.filter = CaseFilter.all});

  final List<Case> items;
  final CaseFilter filter;

  /// The cases the current tab shows.
  List<Case> get visible => items.where(filter.matches).toList();

  /// True only when there are no cases at all — not when a tab is empty. The
  /// two need different copy, so the screen distinguishes them.
  bool get isEmpty => items.isEmpty;

  /// [found] as [list] now holds them, where it holds them at all.
  ///
  /// Search results are a snapshot; writes update the list. Drawing a result
  /// from the list's copy means a case accepted from its result card shows as
  /// accepted at once. A case the list does not hold keeps the search's copy.
  static List<Case> latestOf(List<Case> found, CasesListState? list) {
    final held = {
      for (final value in list?.items ?? const <Case>[]) value.id: value,
    };
    return [for (final value in found) held[value.id] ?? value];
  }

  CasesListState copyWith({List<Case>? items, CaseFilter? filter}) =>
      CasesListState(items: items ?? this.items, filter: filter ?? this.filter);

  @override
  List<Object?> get props => [items, filter];
}

/// The cases list and its selected tab.
class CasesListNotifier extends AsyncNotifier<CasesListState> {
  /// Survives a [refresh] so reloading does not throw the user back to All.
  ///
  /// Held here rather than read off `state`, which is not readable during
  /// [build].
  CaseFilter _filter = CaseFilter.all;

  @override
  Future<CasesListState> build() {
    // One user's cases: the next user to sign in starts from nothing.
    ref.watch(sessionProvider);
    // A case filed from the search flow appears without a pull to refresh.
    ref.watch(casesChangedProvider);
    return _load();
  }

  Future<CasesListState> _load() async {
    final result = await ref.read(casesRepositoryProvider).fetchCases();
    return CasesListState(items: result.unwrapOrThrow(), filter: _filter);
  }

  /// Switches tab. Local work only — no request, so no loading state.
  void selectFilter(CaseFilter filter) {
    if (_filter == filter) return;
    _filter = filter;

    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(filter: filter));
  }

  /// Swaps in a case a write has just returned, leaving the rest untouched.
  ///
  /// Cheaper and more truthful than re-fetching the list: the response is the
  /// server's own updated record, and the row changes the moment the write
  /// lands rather than a round trip later.
  ///
  /// Does nothing when the list has not been loaded, or does not hold the case
  /// — the next load will bring it in correctly either way.
  void replaceCase(Case value) {
    final current = state.value;
    if (current == null) return;

    final index = current.items.indexWhere((item) => item.id == value.id);
    if (index == -1) return;

    final items = List<Case>.of(current.items)..[index] = value;
    state = AsyncData(current.copyWith(items: items));
  }

  Future<void>? _reloading;

  /// Reloads. Backs pull-to-refresh, the error-state retry and [revisit]; a
  /// reload already under way is joined, not repeated.
  Future<void> refresh() => _reloading ??= AsyncValue.guard(
    _load,
  ).then((value) => state = value).whenComplete(() => _reloading = null);

  /// Re-reads on coming back to the list, so the other role's changes show.
  /// The rows stay on screen meanwhile. Skipped until a first load has landed:
  /// the screen is already showing its skeleton or its retry.
  Future<void> revisit() async {
    if (!state.hasValue) return;
    await refresh();
  }
}

final casesListProvider =
    AsyncNotifierProvider<CasesListNotifier, CasesListState>(
      CasesListNotifier.new,
    );
