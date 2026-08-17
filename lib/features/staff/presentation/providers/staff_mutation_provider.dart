import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/result.dart';
import '../../domain/entities/staff_draft.dart';
import 'staff_list_provider.dart';
import 'staff_providers.dart';

/// Create, update and deactivate.
///
/// Each method returns whether it succeeded, so the calling sheet can decide
/// to close or stay open. On failure the state holds an `AppFailure`, read back
/// with `AsyncValueFailureX.failure` and shown via `context.showFailure` — the
/// raw exception never reaches the widget.
class StaffMutationNotifier extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<bool> createStaff(StaffDraft draft) =>
      _run(() => ref.read(staffRepositoryProvider).createStaff(draft));

  /// Named `updateStaff` rather than `update`, which `AsyncNotifier` already
  /// defines for mutating its own state.
  Future<bool> updateStaff({
    required String id,
    required StaffDraft draft,
  }) => _run(
    () => ref.read(staffRepositoryProvider).updateStaff(id: id, draft: draft),
  );

  /// Soft-deletes: the record comes back from the list as inactive.
  Future<bool> removeStaff(String id) =>
      _run(() => ref.read(staffRepositoryProvider).deactivateStaff(id));

  Future<bool> _run<T>(Future<Result<T>> Function() action) async {
    state = const AsyncLoading<void>();

    final result = await action();

    return result.fold(
      onOk: (_) {
        state = const AsyncData<void>(null);
        // Re-read the list so the new, edited or deactivated row is reflected.
        ref.invalidate(staffListProvider);
        return true;
      },
      onErr: (failure) {
        state = AsyncError<void>(failure, StackTrace.current);
        return false;
      },
    );
  }
}

final staffMutationProvider =
    AsyncNotifierProvider<StaffMutationNotifier, void>(
      StaffMutationNotifier.new,
    );
