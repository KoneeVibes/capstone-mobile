import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/navigation/app_session.dart';
import '../../../../core/session/cases_changed.dart';
import '../../domain/entities/queue_overview.dart';
import 'dashboard_providers.dart';

/// The two counts above the staff queue. One user's data, so a new session
/// starts empty.
final queueOverviewProvider = FutureProvider<QueueOverview>((ref) async {
  if (ref.watch(sessionProvider) == null) return untilSignedIn();
  ref.watch(casesChangedProvider);
  final result = await ref
      .read(dashboardRepositoryProvider)
      .fetchStaffOverview();
  return result.unwrapOrThrow();
});
