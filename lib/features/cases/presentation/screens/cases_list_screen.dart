import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/error/async_value_x.dart';
import '../../../../shared/widgets/app_state_view.dart';
import '../../domain/entities/case_filter.dart';
import '../providers/cases_list_provider.dart';
import '../widgets/case_filter_bar.dart';
import '../widgets/case_list_skeleton.dart';
import '../widgets/case_list_tile.dart';

/// Every case, filtered by the tab bar, opening onto the detail screen.
class CasesListScreen extends ConsumerWidget {
  const CasesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listState = ref.watch(casesListProvider);
    final notifier = ref.read(casesListProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Cases')),
      body: SafeArea(
        child: Column(
          // Stretch, so the horizontally scrolling filter bar fills the width
          // and starts at the screen inset. Left to itself it sizes to its
          // chips and the Column centres it.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSizing.space12),
            // Outside the state switch: the tabs stay put while the list
            // loads, so nothing below them jumps when the cases arrive.
            CaseFilterBar(
              selected: listState.value?.filter ?? CaseFilter.all,
              enabled: listState.hasValue,
              onSelected: notifier.selectFilter,
            ),
            Expanded(
              child: listState.when2(
                // A skeleton rather than a spinner: the card shape is known,
                // so the list can be previewed and nothing shifts on arrival.
                loading: () => const CaseListSkeleton(),
                error: (failure) => AppStateView.failure(
                  failure: failure,
                  onRetry: notifier.refresh,
                ),
                data: (state) => _CasesList(state: state),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CasesList extends ConsumerWidget {
  const _CasesList({required this.state});

  final CasesListState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refresh = ref.read(casesListProvider.notifier).refresh;
    final visible = state.visible;

    if (visible.isEmpty) {
      return RefreshIndicator(
        onRefresh: refresh,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: _EmptyState(state: state),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: refresh,
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
            return _CountFooter(shown: visible.length, total: state.items.length);
          }

          final value = visible[index];
          return CaseListTile(
            value: value,
            onTap: () => context.pushNamed(
              AppRoutes.caseDetailName,
              pathParameters: {'caseId': value.id},
            ),
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

    final (title, message) = switch (state.filter) {
      CaseFilter.newCases => (
        'No new cases',
        'Every case has been picked up by someone.',
      ),
      CaseFilter.assigned => (
        'No cases assigned',
        'Open a new case to give it to a team member.',
      ),
      CaseFilter.closed => (
        'No closed cases',
        'Cases stay here once the work on them is finished.',
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

/// `2 of 5 cases` — closes the list so the filter's effect is legible.
class _CountFooter extends StatelessWidget {
  const _CountFooter({required this.shown, required this.total});

  final int shown;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSizing.space8),
      child: Center(
        child: Text(
          '$shown of $total ${total == 1 ? 'case' : 'cases'}',
          style: AppTextStyles.bodyMedium,
        ),
      ),
    );
  }
}
