import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/navigation/app_session.dart';
import '../../../../core/session/cases_changed.dart';
import '../../domain/entities/case_overview.dart';
import 'dashboard_providers.dart';

/// The client Home's counts. One user's data, so a new session starts empty;
/// a newly filed case recounts.
final caseOverviewProvider = FutureProvider<CaseOverview>((ref) async {
  ref
    ..watch(sessionProvider)
    ..watch(casesChangedProvider);
  final result = await ref.read(dashboardRepositoryProvider).fetchOverview();
  return result.unwrapOrThrow();
});
