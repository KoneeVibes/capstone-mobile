import 'package:flutter/material.dart';

import '../../../../core/formatting/app_formatters.dart';
import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_shimmer.dart';
import '../../domain/entities/tracked_case.dart';
import '../../domain/entities/tracking_event.dart';
import '../../domain/entities/tracking_status.dart';

enum _Marker { past, current, done }

/// The case's `statusHistory` as a vertical timeline, oldest first.
class TrackingTimeline extends StatelessWidget {
  const TrackingTimeline({required this.value, super.key});

  final TrackedCase value;

  @override
  Widget build(BuildContext context) {
    final history = value.history;
    final lastIndex = history.length - 1;

    return Column(
      children: [
        for (var i = 0; i < history.length; i++)
          _TimelineEntry(
            event: history[i],
            isReassignment: value.isReassignment(i),
            isLast: i == lastIndex,
            marker: i < lastIndex
                ? _Marker.past
                : history[i].status == TrackingStatus.closed
                ? _Marker.done
                : _Marker.current,
          ),
      ],
    );
  }
}

class TrackingTimelineSkeleton extends StatelessWidget {
  const TrackingTimelineSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Column(
        children: [
          for (var i = 0; i < 3; i++)
            const Padding(
              padding: EdgeInsets.only(bottom: AppSizing.space20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppShimmerBox.square(
                    size: AppSizing.iconLg,
                    radius: AppSizing.radiusPill,
                  ),
                  SizedBox(width: AppSizing.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppShimmerBox(width: 120),
                        SizedBox(height: AppSizing.space6),
                        AppShimmerBox(width: 100, height: AppSizing.space16),
                        SizedBox(height: AppSizing.space6),
                        AppShimmerBox(width: 220),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({
    required this.event,
    required this.isReassignment,
    required this.isLast,
    required this.marker,
  });

  final TrackingEvent event;
  final bool isReassignment;
  final bool isLast;
  final _Marker marker;

  @override
  Widget build(BuildContext context) {
    final (title, description) = _copy(event, isReassignment);
    final isPast = marker == _Marker.past;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: AppSizing.iconLg,
            child: Column(
              children: [
                Icon(
                  marker == _Marker.done ? Icons.check_circle : Icons.schedule,
                  size: AppSizing.iconLg,
                  color: isPast ? AppColors.textTertiary : AppColors.primary,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: AppSizing.timelineConnectorWidth,
                      margin: const EdgeInsets.symmetric(
                        vertical: AppSizing.space4,
                      ),
                      color: AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSizing.space12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSizing.space20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppFormatters.dateTime(event.changedAt),
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: AppSizing.space2),
                  Text(
                    title,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: isPast
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: AppSizing.space2),
                    Text(description, style: AppTextStyles.bodySmall),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// (title, description)
  static (String, String) _copy(TrackingEvent event, bool isReassignment) {
    final name = event.assigneeName;
    final hasName = name != null && name.isNotEmpty;

    return switch (event.status) {
      TrackingStatus.submitted => (
        'Submitted',
        'Request received and waiting for payment to be confirmed.',
      ),
      TrackingStatus.paymentValidated => (
        'Payment validated',
        'Payment confirmed and waiting to be picked up by the team.',
      ),
      TrackingStatus.assigned when isReassignment => (
        'Re-assigned',
        hasName ? 'Handed on to $name.' : 'Handed on to another staff member.',
      ),
      TrackingStatus.assigned => (
        'Assigned',
        hasName
            ? 'Allocated to $name, who will begin shortly.'
            : 'A staff member has been allocated and will begin shortly.',
      ),
      TrackingStatus.accepted => (
        'Accepted',
        'The search is underway and actively being worked on.',
      ),
      TrackingStatus.pendingInformation => (
        'Pending information',
        'On hold until the applicant sends more details.',
      ),
      TrackingStatus.underReview => (
        'Under review',
        'Records are being checked for litigation and disputes.',
      ),
      TrackingStatus.closed => (
        'Closed',
        'The search is complete and the documents are ready.',
      ),
      TrackingStatus.suspended => (
        'Suspended',
        'This request was halted and will not be processed further.',
      ),
      TrackingStatus.unknown => ('Status updated', ''),
    };
  }
}
