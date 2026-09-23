import 'package:flutter/material.dart';

import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/recent_search.dart';
import 'tracking_icon_tile.dart';
import 'tracking_status_chip.dart';

class RecentSearchTile extends StatelessWidget {
  const RecentSearchTile({required this.value, required this.onTap, super.key});

  final RecentSearch value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSizing.radiusLg);
    final status = TrackingStatusChip.labelOf(value.status);
    final subtitle = [
      value.trackingId,
      if (status.isNotEmpty) status,
    ].join(' · ');

    return Material(
      color: AppColors.surface,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.all(AppSizing.space16),
          child: Row(
            children: [
              const TrackingIconTile(),
              const SizedBox(width: AppSizing.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value.address ?? value.trackingId,
                      style: AppTextStyles.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSizing.space2),
                    Text(subtitle, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
