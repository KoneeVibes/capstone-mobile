import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/navigation/app_session.dart';
import '../../../../core/network/api_provider.dart';
import '../../data/datasources/cases_datasource.dart';
import '../../data/datasources/cases_remote_datasource.dart';
import '../../data/repositories/cases_repository_impl.dart';
import '../../domain/entities/case_assignee.dart';
import '../../domain/repositories/cases_repository.dart';

/// Wiring for the cases feature.
///
/// Tests override [casesRepositoryProvider] to run the notifiers against a mock
/// without touching the datasource.

final casesDataSourceProvider = Provider<CasesDataSource>(
  (ref) => CasesRemoteDataSourceImpl(
    ref.watch(apiClientProvider),
    // Names come from `GET /staff`, which only some staff roles may read.
    resolveAssignees:
        ref.watch(sessionProvider)?.permissions.canViewStaff ?? false,
  ),
);

final casesRepositoryProvider = Provider<CasesRepository>(
  (ref) => CasesRepositoryImpl(ref.watch(casesDataSourceProvider)),
);

/// The team members a case may be given to. Active staff only.
final caseAssigneesProvider = FutureProvider<List<CaseAssignee>>((ref) async {
  final result = await ref.watch(casesRepositoryProvider).fetchAssignees();
  return result.unwrapOrThrow();
});
