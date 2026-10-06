import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/navigation/app_session.dart';
import '../../../../core/session/staff_permissions.dart';
import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/error/app_failure.dart';
import '../../../../core/utils/error/async_value_x.dart';
import '../../../../shared/extensions/context_extensions.dart';
import '../../../../shared/widgets/app_confirm_dialog.dart';
import '../../../../shared/widgets/app_search_field.dart';
import '../../../../shared/widgets/app_state_view.dart';
import '../../domain/entities/staff.dart';
import '../providers/staff_list_provider.dart';
import '../providers/staff_mutation_provider.dart';
import '../widgets/staff_form_sheet.dart';
import '../widgets/staff_list_skeleton.dart';
import '../widgets/staff_list_tile.dart';

/// Staff management: list, add, edit and remove — each action shown only to
/// roles that may take it.
class StaffListScreen extends ConsumerStatefulWidget {
  const StaffListScreen({super.key});

  @override
  ConsumerState<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends ConsumerState<StaffListScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final remaining = position.maxScrollExtent - position.pixels;

    if (remaining <= AppConstants.infiniteScrollThreshold) {
      // The notifier ignores the call when it is already loading, at the last
      // page, or still building, so firing on every scroll frame is safe.
      unawaited(ref.read(staffListProvider.notifier).loadMore());
    }
  }

  Future<void> _openForm({Staff? staff}) async {
    final saved = await showStaffFormSheet(context: context, staff: staff);
    if (saved != true || !mounted) return;

    context.showMessage(
      staff == null ? 'Staff member added.' : 'Changes saved.',
    );
  }

  Future<void> _confirmRemove(Staff staff) async {
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Remove ${staff.firstName}?',
      message:
          "${staff.fullName} will be removed from staff. This can't be undone.",
      confirmLabel: 'Remove',
      cancelLabel: 'Keep',
    );

    if (!confirmed || !mounted) return;

    final removed = await ref
        .read(staffMutationProvider.notifier)
        .removeStaff(staff.id);

    if (!mounted) return;

    if (removed) {
      context.showMessage('${staff.shortName} was removed.');
      return;
    }

    final failure = ref.read(staffMutationProvider).failure;
    if (failure != null) context.showFailure(failure);
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(staffListProvider);
    final permissions =
        ref.watch(sessionProvider)?.permissions ?? StaffPermissions.none;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff'),
        actions: [
          if (permissions.canCreateStaff) ...[
            _AddNewButton(onPressed: _openForm),
            const SizedBox(width: AppSizing.screenPadding),
          ],
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(
                AppSizing.screenPadding,
                AppSizing.space12,
                AppSizing.screenPadding,
                AppSizing.space12,
              ),
              // Disabled until the list endpoint supports a search parameter.
              child: AppSearchField(
                hint: 'Search staff by name, email or role',
                enabled: false,
              ),
            ),
            Expanded(
              child: listState.when2(
                // A skeleton rather than a spinner: the row shape is known, so
                // the list can be previewed and nothing shifts on arrival.
                loading: () => const StaffListSkeleton(),
                error: (failure) => AppStateView.failure(
                  failure: failure,
                  onRetry: () =>
                      ref.read(staffListProvider.notifier).refresh(),
                ),
                data: (state) => _buildList(state, permissions),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(StaffListState state, StaffPermissions permissions) {
    final refresh = ref.read(staffListProvider.notifier).refresh;

    if (state.isEmpty) {
      // The design's "No Matches" state belongs to search, which is disabled;
      // this is the genuinely-no-records case.
      return RefreshIndicator(
        onRefresh: refresh,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: AppStateView.empty(
                icon: Icons.people_outline,
                title: 'No staff yet',
                message: permissions.canCreateStaff
                    ? 'Add your first staff member to get started.'
                    : 'Staff members will appear here once they are added.',
              ),
            ),
          ),
        ),
      );
    }

    final hasFooter = state.isLoadingMore || state.loadMoreFailure != null;

    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSizing.screenPadding,
          0,
          AppSizing.screenPadding,
          AppSizing.space24,
        ),
        itemCount: state.items.length + (hasFooter ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: AppSizing.space12),
        itemBuilder: (context, index) {
          if (index >= state.items.length) {
            return _ListFooter(
              failure: state.loadMoreFailure,
              onRetry: () => ref.read(staffListProvider.notifier).loadMore(),
            );
          }

          final staff = state.items[index];
          return StaffListTile(
            staff: staff,
            onEdit: permissions.canEditStaff
                ? () => _openForm(staff: staff)
                : null,
            onRemove: permissions.canDeleteStaff
                ? () => _confirmRemove(staff)
                : null,
          );
        },
      ),
    );
  }
}

/// Outlined "Add New" action in the app bar.
class _AddNewButton extends StatelessWidget {
  const _AddNewButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSizing.radiusPill),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppSizing.radiusPill),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizing.radiusPill),
            border: Border.all(
              color: AppColors.border,
              width: AppSizing.borderWidth,
            ),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSizing.space16,
              vertical: AppSizing.space8,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: AppSizing.iconSm),
                SizedBox(width: AppSizing.space6),
                Text('Add New', style: AppTextStyles.label),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Spinner while the next page loads, or an inline retry when it failed.
///
/// A failed page does not replace the rows already loaded, so this sits at the
/// bottom of the list rather than taking over the screen.
class _ListFooter extends StatelessWidget {
  const _ListFooter({required this.failure, required this.onRetry});

  final AppFailure? failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final loadFailure = failure;

    if (loadFailure == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSizing.space20),
        child: Center(
          child: SizedBox(
            height: AppSizing.iconLg,
            width: AppSizing.iconLg,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizing.space16),
      child: Column(
        children: [
          Text(
            loadFailure.message,
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizing.space8),
          TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}
