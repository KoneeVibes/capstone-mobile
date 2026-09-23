import 'package:flutter/material.dart';

import '../../../../core/formatting/app_formatters.dart';
import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_shimmer.dart';
import '../../domain/entities/tracked_case.dart';
import 'tracking_icon_tile.dart';
import 'tracking_status_chip.dart';

/// What a successful lookup found.
class TrackingResultCard extends StatelessWidget {
  const TrackingResultCard({required this.value, super.key});

  final TrackedCase value;

  @override
  Widget build(BuildContext context) {
    final address = value.address;
    final updatedAt = value.updatedAt;

    return Column(
      children: [
        Row(
          children: [
            const TrackingIconTile(),
            const SizedBox(width: AppSizing.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    address ?? value.trackingId,
                    style: AppTextStyles.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (address != null)
                    Text(value.trackingId, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizing.space16),
        _DetailRow(
          label: 'Tracking ID',
          child: Text(value.trackingId, style: AppTextStyles.titleSmall),
        ),
        const Divider(),
        _DetailRow(
          label: 'Status',
          child: TrackingStatusChip(status: value.status),
        ),
        if (updatedAt != null) ...[
          const Divider(),
          _DetailRow(
            label: 'Last updated',
            child: Text(
              AppFormatters.dateTime(updatedAt),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class TrackingResultSkeleton extends StatelessWidget {
  const TrackingResultSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Column(
        children: [
          const Row(
            children: [
              AppShimmerBox.square(size: AppSizing.iconButtonSize),
              SizedBox(width: AppSizing.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppShimmerBox(width: 180, height: AppSizing.space16),
                    SizedBox(height: AppSizing.space6),
                    AppShimmerBox(width: 100),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizing.space16),
          for (var i = 0; i < 3; i++)
            const _DetailRow(
              label: '',
              skeleton: true,
              child: AppShimmerBox(width: 90, height: AppSizing.space16),
            ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.child,
    this.skeleton = false,
  });

  final String label;
  final Widget child;
  final bool skeleton;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizing.space12),
      child: Row(
        children: [
          Expanded(
            child: skeleton
                ? const Align(
                    alignment: Alignment.centerLeft,
                    child: AppShimmerBox(width: 80),
                  )
                : Text(label, style: AppTextStyles.bodyMedium),
          ),
          child,
        ],
      ),
    );
  }
}
