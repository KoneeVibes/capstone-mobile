import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/formatting/app_formatters.dart';
import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/error/async_value_x.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_state_view.dart';
import '../providers/tracking_provider.dart';
import '../widgets/tracking_back_button.dart';
import '../widgets/tracking_banner.dart';
import '../widgets/tracking_panel.dart';
import '../widgets/tracking_timeline.dart';

/// The status history of one tracked case.
class TrackingProgressScreen extends ConsumerStatefulWidget {
  const TrackingProgressScreen({
    required this.trackingId,
    required this.fallbackRouteName,
    super.key,
  });

  final String trackingId;

  /// Where back goes when there is nothing to pop, as after a deep link.
  final String fallbackRouteName;

  @override
  ConsumerState<TrackingProgressScreen> createState() =>
      _TrackingProgressScreenState();
}

class _TrackingProgressScreenState
    extends ConsumerState<TrackingProgressScreen> {
  late final String _trackingId = AppFormatters.trackingId(widget.trackingId);
  late final String? _invalid = Validators.trackingId(_trackingId);

  @override
  void initState() {
    super.initState();
    // Reached by deep link, or the dashboard has since searched something else.
    final current = ref.read(trackingProvider).value?.trackingId;
    if (_invalid == null && current != _trackingId) Future.microtask(_load);
  }

  void _load() => ref.read(trackingProvider.notifier).track(_trackingId);

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(widget.fallbackRouteName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSizing.screenPadding),
          children: [
            const TrackingBanner(),
            const SizedBox(height: AppSizing.space12),
            TrackingPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TrackingBackButton(onPressed: _back),
                  const SizedBox(height: AppSizing.space16),
                  const Text('Track Progress', style: AppTextStyles.label),
                  const SizedBox(height: AppSizing.space20),
                  _body(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    final invalid = _invalid;
    if (invalid != null) {
      return AppStateView.empty(
        icon: Icons.search_off,
        title: 'Tracking ID not recognised',
        message: invalid,
      );
    }

    final tracking = ref.watch(trackingProvider);
    final value = tracking.value;
    final failure = tracking.failure;

    if (!tracking.isLoading && failure != null) {
      return AppStateView.failure(
        failure: failure,
        onRetry: failure.isRetryable ? _load : null,
      );
    }
    if (tracking.isLoading || value?.trackingId != _trackingId) {
      return const TrackingTimelineSkeleton();
    }
    if (value!.history.isEmpty) {
      return const AppStateView.empty(
        icon: Icons.timeline,
        title: 'No progress recorded yet',
      );
    }
    return TrackingTimeline(value: value);
  }
}
