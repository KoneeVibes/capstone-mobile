import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/navigation/app_session.dart';
import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/error/async_value_x.dart';
import '../../../../core/utils/search_query.dart';
import '../../../../shared/widgets/app_search_field.dart';
import '../../../../shared/widgets/app_state_view.dart';
import '../../domain/entities/case.dart';
import '../../domain/entities/case_filter.dart';
import '../case_action_runner.dart';
import '../providers/case_search_provider.dart';
import '../providers/cases_list_provider.dart';
import '../widgets/case_filter_bar.dart';
import '../widgets/case_list_skeleton.dart';
import '../widgets/case_list_tile.dart';
import '../widgets/revisit_cases_list.dart';

/// Every case, filtered by the tab bar, opening onto the detail screen.
///
/// Mounted in both shells; the server scopes the list to what the signed-in
/// user may see.
class CasesListScreen extends ConsumerStatefulWidget {
  const CasesListScreen({
    required this.detailRouteName,
    required this.chatRouteName,
    this.payRouteName,
    this.trackRouteName,
    super.key,
  });

  /// The detail route inside the shell this list lives in.
  final String detailRouteName;

  /// The case conversation for this role. Takes a `caseId` path parameter.
  final String chatRouteName;

  /// The route that pays a case's invoice. Null in the staff shell, where
  /// nobody pays; set in the client shell.
  final String? payRouteName;

  /// The client's progress timeline. Takes `caseId` and `trackingId` path
  /// parameters; null in the staff shell.
  final String? trackRouteName;

  @override
  ConsumerState<CasesListScreen> createState() => _CasesListScreenState();
}

class _CasesListScreenState extends ConsumerState<CasesListScreen>
    with RevisitCasesList {
  // Seeded from the provider, so the bar survives a rebuild of the tab.
  late final _search = TextEditingController(
    text: ref.read(caseSearchQueryProvider),
  );
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      AppConstants.searchDebounce,
      () => ref.read(caseSearchQueryProvider.notifier).change(value),
    );
  }

  void _clearSearch() {
    _debounce?.cancel();
    _search.clear();
    ref.read(caseSearchQueryProvider.notifier).change('');
  }

  /// Re-runs the search. Its failure shows as the error state, so it is not
  /// rethrown into the pull-to-refresh.
  Future<void> _refreshSearch() async {
    ref.invalidate(caseSearchProvider);
    try {
      await ref.read(caseSearchProvider.future);
    } on Object {
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(casesListProvider);
    final notifier = ref.read(casesListProvider.notifier);
    final query = searchQueryFrom(ref.watch(caseSearchQueryProvider));
    final filter = listState.value?.filter ?? CaseFilter.all;

    return Scaffold(
      appBar: AppBar(title: const Text('Cases')),
      body: SafeArea(
        child: Column(
          // Stretch, so the horizontally scrolling filter bar fills the width
          // and starts at the screen inset. Left to itself it sizes to its
          // chips and the Column centres it.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizing.screenPadding,
                AppSizing.space12,
                AppSizing.screenPadding,
                AppSizing.space12,
              ),
              child: AppSearchField(
                hint: 'Search by reference, name or address',
                controller: _search,
                onChanged: _onSearchChanged,
                onClear: _clearSearch,
              ),
            ),
            // Outside the state switch: the tabs stay put while the list
            // loads, so nothing below them jumps when the cases arrive. They
            // filter search results too.
            CaseFilterBar(
              selected: filter,
              enabled: listState.hasValue,
              onSelected: notifier.selectFilter,
            ),
            Expanded(
              child: query == null
                  ? listState.when2(
                      // A skeleton rather than a spinner: the card shape is
                      // known, so the list can be previewed and nothing shifts
                      // on arrival.
                      loading: () => const CaseListSkeleton(),
                      error: (failure) => AppStateView.failure(
                        failure: failure,
                        onRetry: notifier.refresh,
                      ),
                      data: (state) =>
                          _list(state, onRefresh: notifier.refresh),
                    )
                  : ref
                        .watch(caseSearchProvider)
                        .when2(
                          loading: () => const CaseListSkeleton(),
                          error: (failure) => AppStateView.failure(
                            failure: failure,
                            onRetry: () => ref.invalidate(caseSearchProvider),
                          ),
                          data: (found) => _list(
                            CasesListState(
                              // The list's own copies where it has them, so a
                              // write from a result card shows at once.
                              items: CasesListState.latestOf(
                                found ?? const [],
                                listState.value,
                              ),
                              filter: filter,
                            ),
                            onRefresh: _refreshSearch,
                            searchQuery: query,
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list(
    CasesListState state, {
    required Future<void> Function() onRefresh,
    String? searchQuery,
  }) => _CasesList(
    state: state,
    onRefresh: onRefresh,
    searchQuery: searchQuery,
    detailRouteName: widget.detailRouteName,
    chatRouteName: widget.chatRouteName,
    payRouteName: widget.payRouteName,
    trackRouteName: widget.trackRouteName,
  );
}

class _CasesList extends ConsumerWidget {
  const _CasesList({
    required this.state,
    required this.onRefresh,
    required this.detailRouteName,
    required this.chatRouteName,
    this.searchQuery,
    this.payRouteName,
    this.trackRouteName,
  });

  final CasesListState state;
  final Future<void> Function() onRefresh;

  /// Set while the list is search results, which changes its empty state and
  /// footer.
  final String? searchQuery;

  final String detailRouteName;
  final String chatRouteName;
  final String? payRouteName;
  final String? trackRouteName;

  /// Pay now while unpaid, then Track progress.
  (String?, VoidCallback?) _clientAction(
    BuildContext context,
    Case value, {
    required bool canPay,
  }) {
    final payRoute = payRouteName;
    if (canPay && payRoute != null && value.status.isAwaitingPayment) {
      return (
        'Pay now',
        () => context.pushNamed(payRoute, pathParameters: {'caseId': value.id}),
      );
    }
    final trackRoute = trackRouteName;
    final trackingId = value.trackingId;
    // Older records carry no tracking id, so there is nothing to track by.
    if (trackRoute == null || trackingId == null) return (null, null);
    return (
      'Track progress',
      () => context.pushNamed(
        trackRoute,
        pathParameters: {'caseId': value.id, 'trackingId': trackingId},
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = state.visible;
    final session = ref.watch(sessionProvider);
    final isStaff = session?.isStaff ?? false;
    final canPay = session?.canPayForCases ?? false;
    final viewer = caseViewerOf(ref);
    final searchQuery = this.searchQuery;

    if (visible.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: searchQuery != null
                  ? _SearchEmptyState(query: searchQuery, state: state)
                  : isStaff
                  ? _EmptyState(state: state)
                  : _ClientEmptyState(state: state),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSizing.screenPadding,
          AppSizing.space12,
          AppSizing.screenPadding,
          AppSizing.space24,
        ),
        // One extra row for the count that closes the list.
        itemCount: visible.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: AppSizing.space12),
        itemBuilder: (context, index) {
          if (index == visible.length) {
            return _CountFooter(
              shown: visible.length,
              total: state.items.length,
              isSearch: searchQuery != null,
            );
          }

          final value = visible[index];
          final (label, onAction) = isStaff
              ? staffCardButton(
                  context: context,
                  ref: ref,
                  value: value,
                  viewer: viewer,
                  chatRouteName: chatRouteName,
                )
              : _clientAction(context, value, canPay: canPay);
          return CaseListTile(
            value: value,
            onTap: () async {
              await context.pushNamed(
                detailRouteName,
                pathParameters: {'caseId': value.id},
              );
              // Back from the case: pick up what changed meanwhile.
              if (context.mounted) {
                unawaited(ref.read(casesListProvider.notifier).revisit());
              }
            },
            actionLabel: label,
            onAction: onAction,
          );
        },
      ),
    );
  }
}

/// Nothing to show, worded for the reason there is nothing.
///
/// An inbox with no cases at all and a tab that happens to be empty are
/// different situations, and telling a user "no cases yet" when four are one
/// tap away would be wrong.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.state});

  final CasesListState state;

  @override
  Widget build(BuildContext context) {
    if (state.isEmpty) {
      return const AppStateView.empty(
        icon: Icons.inbox_outlined,
        title: 'No cases yet',
        message: 'New client requests will appear here as they come in.',
      );
    }

    // One line per tab, naming what would be here rather than repeating the
    // tab's own label back at the user.
    final (title, message) = switch (state.filter) {
      CaseFilter.submitted => (
        'No new cases',
        'Cases arrive here when an applicant submits one, and stay until their '
            'payment is validated.',
      ),
      CaseFilter.paymentValidated => (
        'Nothing waiting to be assigned',
        'Cases land here once payment clears, ready to be given to a team '
            'member.',
      ),
      CaseFilter.assigned => (
        'No cases assigned',
        'Cases given to a team member wait here until they pick them up.',
      ),
      CaseFilter.accepted => (
        'No cases accepted',
        'Cases move here once the team member they were given to picks them up.',
      ),
      CaseFilter.pendingInformation => (
        'Nothing waiting on an applicant',
        'Cases stalled for something from the applicant collect here.',
      ),
      CaseFilter.underReview => (
        'No cases under review',
        'Cases wait here once a report is in, until it is accepted.',
      ),
      CaseFilter.closed => (
        'No closed cases',
        'Cases stay here once the work on them is finished.',
      ),
      CaseFilter.suspended => (
        'No suspended cases',
        'Cases halted before they could be finished show here.',
      ),
      CaseFilter.disputed => (
        'No disputed cases',
        'Cases a client has disputed wait here for a new report.',
      ),
      // Unreachable: an empty All tab means no cases at all, handled above.
      CaseFilter.all => ('No cases yet', null),
    };

    return AppStateView.empty(
      icon: Icons.filter_list_off_outlined,
      title: title,
      message: message,
    );
  }
}

/// The client's empty state. The staff copy talks about assigning work, which
/// is not a client's concern.
class _ClientEmptyState extends StatelessWidget {
  const _ClientEmptyState({required this.state});

  final CasesListState state;

  @override
  Widget build(BuildContext context) {
    if (state.isEmpty) {
      return const AppStateView.empty(
        icon: Icons.inbox_outlined,
        title: 'No cases yet',
        message: 'Property searches you request will appear here.',
      );
    }

    return const AppStateView.empty(
      icon: Icons.filter_list_off_outlined,
      title: 'Nothing at this stage',
      message: 'None of your cases are at this stage right now.',
    );
  }
}

/// What a search found nothing for: no match at all, or none under this tab.
class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState({required this.query, required this.state});

  final String query;
  final CasesListState state;

  @override
  Widget build(BuildContext context) {
    if (state.isEmpty) {
      return AppStateView.empty(
        icon: Icons.search_off,
        title: 'No cases match "$query"',
        message: 'Try a reference like PI-…, a name or part of an address.',
      );
    }

    final count = state.items.length;
    return AppStateView.empty(
      icon: Icons.filter_list_off_outlined,
      title: 'No matches at this stage',
      message: count == 1
          ? 'The one match is under another tab.'
          : 'All $count matches are under other tabs.',
    );
  }
}

/// `2 of 5 cases`, or `2 of 3 results` while searching — closes the list so
/// the filter's effect is legible.
class _CountFooter extends StatelessWidget {
  const _CountFooter({
    required this.shown,
    required this.total,
    this.isSearch = false,
  });

  final int shown;
  final int total;
  final bool isSearch;

  @override
  Widget build(BuildContext context) {
    final noun = isSearch ? 'result' : 'case';
    return Padding(
      padding: const EdgeInsets.only(top: AppSizing.space8),
      child: Center(
        child: Text(
          '$shown of $total ${total == 1 ? noun : '${noun}s'}',
          style: AppTextStyles.bodyMedium,
        ),
      ),
    );
  }
}
