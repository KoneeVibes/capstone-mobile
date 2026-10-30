import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/error/async_value_x.dart';
import '../../../../shared/widgets/app_chip.dart';
import '../../domain/case_actions.dart';
import '../../domain/entities/case.dart';
import '../../domain/entities/case_queue_filter.dart';
import '../case_action_runner.dart';
import '../providers/cases_list_provider.dart';
import 'case_error_banner.dart';
import 'case_list_skeleton.dart';
import 'case_list_tile.dart';
import 'revisit_cases_list.dart';

/// The staff home's "My queue": the most recently changed cases, as the same
/// cards and buttons the Cases tab draws (ADR 0019).
///
/// Lives in the cases feature so the action rules stay in one place; the
/// router hands it to the home screen. Reads the Cases tab's own list, so a
/// write on either screen shows on both; it re-reads that list when the home
/// tab comes back into view.
class CaseQueueSection extends ConsumerStatefulWidget {
  const CaseQueueSection({
    required this.detailRouteName,
    required this.chatRouteName,
    required this.viewAllRouteName,
    super.key,
  });

  /// Most cards the queue shows; View all opens the rest.
  static const int maxCards = 5;

  /// Takes a `caseId` path parameter.
  final String detailRouteName;

  /// Takes a `caseId` path parameter.
  final String chatRouteName;

  final String viewAllRouteName;

  @override
  ConsumerState<CaseQueueSection> createState() => _CaseQueueSectionState();
}

class _CaseQueueSectionState extends ConsumerState<CaseQueueSection>
    with RevisitCasesList {
  CaseQueueFilter _filter = CaseQueueFilter.all;

  static String _label(CaseQueueFilter filter) => switch (filter) {
    CaseQueueFilter.all => 'All',
    CaseQueueFilter.fresh => 'New',
    CaseQueueFilter.assigned => 'Assigned',
    CaseQueueFilter.closed => 'Closed',
  };

  Widget _card(Case value, CaseViewer viewer) {
    final (label, onAction) = staffCardButton(
      context: context,
      ref: ref,
      value: value,
      viewer: viewer,
      chatRouteName: widget.chatRouteName,
    );
    return CaseListTile(
      value: value,
      // Into the Cases tab, so back lands on the list there.
      onTap: () => context.goNamed(
        widget.detailRouteName,
        pathParameters: {'caseId': value.id},
      ),
      actionLabel: label,
      onAction: onAction,
    );
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(casesListProvider);
    final viewer = caseViewerOf(ref);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('My queue', style: AppTextStyles.titleMedium),
            ),
            GestureDetector(
              onTap: () => context.goNamed(widget.viewAllRouteName),
              behavior: HitTestBehavior.opaque,
              child: const Text('View all', style: AppTextStyles.link),
            ),
          ],
        ),
        const SizedBox(height: AppSizing.space12),
        Wrap(
          spacing: AppSizing.space8,
          runSpacing: AppSizing.space8,
          children: [
            for (final filter in CaseQueueFilter.values)
              AppChoiceChip(
                label: _label(filter),
                isSelected: filter == _filter,
                style: AppChoiceChipStyle.neutral,
                enabled: listState.hasValue,
                onSelected: () => setState(() => _filter = filter),
              ),
          ],
        ),
        const SizedBox(height: AppSizing.space16),
        listState.when2(
          loading: () => const Column(
            children: [
              CaseCardSkeleton(),
              SizedBox(height: AppSizing.space12),
              CaseCardSkeleton(),
            ],
          ),
          error: (failure) => CaseErrorBanner(
            failure: failure,
            onRetry: ref.read(casesListProvider.notifier).refresh,
          ),
          data: (state) {
            final cases = _filter.pick(
              state.items,
              limit: CaseQueueSection.maxCards,
            );
            if (cases.isEmpty) return const _Empty();

            return Column(
              children: [
                for (final (index, value) in cases.indexed) ...[
                  if (index != 0) const SizedBox(height: AppSizing.space12),
                  _card(value, viewer),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

/// When a tab has nothing under it.
class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSizing.space32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
      ),
      child: const Text(
        'Nothing in this tab.',
        style: AppTextStyles.bodyMedium,
        textAlign: TextAlign.center,
      ),
    );
  }
}
