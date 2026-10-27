import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/navigation/app_session.dart';
import '../../../../core/session/cases_changed.dart';
import '../../../../core/utils/search_query.dart';
import '../../domain/entities/case.dart';
import 'cases_providers.dart';

/// What the Cases tab's search bar holds, already debounced by the screen.
class CaseSearchQueryNotifier extends Notifier<String> {
  @override
  String build() {
    // The next user to sign in starts with an empty bar.
    ref.watch(sessionProvider);
    return '';
  }

  void change(String value) => state = value;
}

final caseSearchQueryProvider =
    NotifierProvider<CaseSearchQueryNotifier, String>(
      CaseSearchQueryNotifier.new,
    );

/// The cases matching the search bar, or null while it holds too little to
/// send — which the screen reads as "show the whole list".
///
/// Never retried: a failed search is the user's to repeat, from the retry on
/// the error state.
final caseSearchProvider = FutureProvider.autoDispose<List<Case>?>((ref) async {
  ref.watch(sessionProvider);
  ref.watch(casesChangedProvider);
  final query = searchQueryFrom(ref.watch(caseSearchQueryProvider));
  if (query == null) return null;

  final result = await ref.read(casesRepositoryProvider).searchCases(query);
  return result.unwrapOrThrow();
}, retry: (_, _) => null);
