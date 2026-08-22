import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/error/app_failure.dart';
import '../../../../core/utils/error/async_value_x.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_bottom_sheet.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_shimmer.dart';
import '../../domain/entities/case.dart';
import '../../domain/entities/case_assignee.dart';
import '../providers/case_assignment_provider.dart';
import '../providers/cases_providers.dart';

/// Opens the assign sheet. Resolves to true when the case was assigned.
Future<bool?> showCaseAssignSheet({
  required BuildContext context,
  required Case value,
}) => showAppBottomSheet<bool>(
  context: context,
  title: 'Assign case',
  child: CaseAssignSheet(value: value),
);

/// Picks a team member and writes the assignment.
///
/// One sheet for both assigning and re-assigning: the only difference is that
/// re-assigning opens with the current holder selected, so the user sees who
/// has it before changing it.
class CaseAssignSheet extends ConsumerStatefulWidget {
  const CaseAssignSheet({required this.value, super.key});

  final Case value;

  @override
  ConsumerState<CaseAssignSheet> createState() => _CaseAssignSheetState();
}

class _CaseAssignSheetState extends ConsumerState<CaseAssignSheet> {
  late String? _selectedId = widget.value.assignee?.id;

  /// Held locally rather than read from the shared provider, so a failure from
  /// an earlier assignment cannot appear when the sheet opens.
  AppFailure? _failure;

  /// Nothing to write until a different person is chosen — re-confirming the
  /// current holder would be a request that changes nothing.
  bool get _canConfirm =>
      _selectedId != null && _selectedId != widget.value.assignee?.id;

  Future<void> _submit() async {
    setState(() => _failure = null);

    final assigned = await ref
        .read(caseAssignmentProvider.notifier)
        .assign(caseId: widget.value.id, assigneeId: _selectedId!);

    if (!mounted) return;

    if (assigned) {
      Navigator.of(context).pop(true);
      return;
    }

    // Shown inline: a snackbar would sit behind the sheet.
    setState(() => _failure = ref.read(caseAssignmentProvider).failure);
  }

  @override
  Widget build(BuildContext context) {
    final assignees = ref.watch(caseAssigneesProvider);
    final isSaving = ref.watch(caseAssignmentProvider).isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Names the case the sheet is about. There is no case reference to
        // print, so the applicant and their property identify it instead.
        Text(
          [
            widget.value.applicant.name,
            widget.value.summary,
          ].where((part) => part.isNotEmpty).join(' · '),
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: AppSizing.space20),
        assignees.when2(
          loading: () => const _AssigneeListSkeleton(),
          error: (failure) => _SheetError(
            failure: failure,
            onRetry: () => ref.invalidate(caseAssigneesProvider),
          ),
          data: (people) => _AssigneeList(
            people: people,
            selectedId: _selectedId,
            enabled: !isSaving,
            onSelected: (id) => setState(() {
              _selectedId = id;
              _failure = null;
            }),
          ),
        ),
        if (_failure != null) ...[
          const SizedBox(height: AppSizing.space16),
          _SheetError(failure: _failure!),
        ],
        const SizedBox(height: AppSizing.space24),
        AppButton(
          label: 'Confirm',
          variant: AppButtonVariant.secondary,
          isLoading: isSaving,
          onPressed: _canConfirm ? _submit : null,
        ),
      ],
    );
  }
}

class _AssigneeList extends StatelessWidget {
  const _AssigneeList({
    required this.people,
    required this.selectedId,
    required this.enabled,
    required this.onSelected,
  });

  final List<CaseAssignee> people;
  final String? selectedId;
  final bool enabled;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (people.isEmpty) {
      return const Text(
        'There is nobody to assign this case to yet.',
        style: AppTextStyles.bodyMedium,
      );
    }

    return Column(
      children: [
        for (final person in people)
          _AssigneeOption(
            person: person,
            isSelected: person.id == selectedId,
            enabled: enabled,
            onSelected: () => onSelected(person.id),
          ),
      ],
    );
  }
}

/// One selectable team member.
class _AssigneeOption extends StatelessWidget {
  const _AssigneeOption({
    required this.person,
    required this.isSelected,
    required this.enabled,
    required this.onSelected,
  });

  final CaseAssignee person;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        checked: isSelected,
        inMutuallyExclusiveGroup: true,
        child: InkWell(
          onTap: enabled ? onSelected : null,
          borderRadius: BorderRadius.circular(AppSizing.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizing.space12),
            child: Row(
              children: [
                AppAvatar(
                  initials: person.initials,
                  imageUrl: person.avatarUrl,
                  size: AppSizing.avatarSm,
                ),
                const SizedBox(width: AppSizing.space12),
                Expanded(
                  child: Text(
                    person.fullName,
                    style: AppTextStyles.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSizing.space12),
                _SelectionDot(isSelected: isSelected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The radio mark on an assignee row.
///
/// Drawn rather than using Material's Radio so the ring and fill come from
/// [AppColors], and so the control does not have to be re-plumbed as Material
/// reworks its own radio API.
class _SelectionDot extends StatelessWidget {
  const _SelectionDot({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSizing.iconMd,
      width: AppSizing.iconMd,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? AppColors.primary : AppColors.surface,
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: AppSizing.borderWidthFocused,
        ),
      ),
      child: isSelected
          ? Center(
              child: Container(
                height: AppSizing.space6,
                width: AppSizing.space6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.textOnPrimary,
                ),
              ),
            )
          : null,
    );
  }
}

class _AssigneeListSkeleton extends StatelessWidget {
  const _AssigneeListSkeleton();

  /// About as many people as a team has, so the sheet barely resizes when the
  /// real list arrives.
  static const int _rowCount = 4;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Column(
        children: [
          for (var i = 0; i < _rowCount; i++)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSizing.space12),
              child: Row(
                children: [
                  AppShimmerBox.square(size: AppSizing.avatarSm),
                  SizedBox(width: AppSizing.space12),
                  AppShimmerBox(width: 130, height: AppSizing.space16),
                  Spacer(),
                  AppShimmerBox(
                    width: AppSizing.iconMd,
                    height: AppSizing.iconMd,
                    radius: AppSizing.radiusPill,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Inline failure banner. Renders [AppFailure.message] and nothing else.
class _SheetError extends StatelessWidget {
  const _SheetError({required this.failure, this.onRetry});

  final AppFailure failure;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final showRetry = onRetry != null && failure.isRetryable;

    return Container(
      padding: const EdgeInsets.all(AppSizing.space12),
      decoration: BoxDecoration(
        color: AppColors.destructiveSoft,
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            size: AppSizing.iconSm,
            color: AppColors.destructive,
          ),
          const SizedBox(width: AppSizing.space8),
          Expanded(
            child: Text(
              failure.message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.destructive,
              ),
            ),
          ),
          if (showRetry)
            TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}
