import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/navigation/app_session.dart';
import '../../../../core/utils/search_query.dart';
import '../../domain/entities/staff.dart';
import 'staff_providers.dart';

/// What the Staff tab's search bar holds, already debounced by the screen.
class StaffSearchQueryNotifier extends Notifier<String> {
  @override
  String build() {
    // The next user to sign in starts with an empty bar.
    ref.watch(sessionProvider);
    return '';
  }

  void change(String value) => state = value;
}

final staffSearchQueryProvider =
    NotifierProvider<StaffSearchQueryNotifier, String>(
      StaffSearchQueryNotifier.new,
    );

/// The staff matching the search bar, or null while it holds too little to
/// send — which the screen reads as "show the whole list".
///
/// Never retried: a failed search is the user's to repeat, from the retry on
/// the error state.
final staffSearchProvider = FutureProvider.autoDispose<List<Staff>?>((
  ref,
) async {
  ref.watch(sessionProvider);
  final query = searchQueryFrom(ref.watch(staffSearchQueryProvider));
  if (query == null) return null;

  final result = await ref.read(staffRepositoryProvider).searchStaff(query);
  return result.unwrapOrThrow();
}, retry: (_, _) => null);
