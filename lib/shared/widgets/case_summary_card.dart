import 'package:flutter/material.dart';

import '../../core/sizing/app_sizing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'app_button.dart';

/// The case card both the staff queue and the Cases lists draw: reference and
/// status, the property and the person, and at most one action.
///
/// Takes plain values so neither feature has to import the other's entities;
/// each caller maps its own status to the [status] chip and the action.
class CaseSummaryCard extends StatelessWidget {
  /// Creates the card. [status] is the caller's own chip.
  const CaseSummaryCard({
    required this.title,
    required this.subtitle,
    required this.status,
    super.key,
    this.reference,
    this.trailing,
    this.actionLabel,
    this.onAction,
    this.onTap,
  });

  /// Above the title, in the brand blue. Absent on records without one.
  final String? reference;

  /// The property, e.g. `Block C, Ikoyi Crescent`.
  final String title;

  /// The person the card is about.
  final String subtitle;

  /// The status chip, top right.
  final Widget status;

  /// Beside the subtitle, e.g. the queue's due label.
  final Widget? trailing;

  /// The button's label; no button when null.
  final String? actionLabel;

  /// Null greys the button out.
  final VoidCallback? onAction;

  /// Opens the case.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSizing.radiusLg);
    final reference = this.reference;
    final actionLabel = this.actionLabel;

    return Material(
      color: AppColors.surface,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.all(AppSizing.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Thumbnail(),
                  const SizedBox(width: AppSizing.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                reference ?? '',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.primaryBright,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: AppSizing.space8),
                            status,
                          ],
                        ),
                        const SizedBox(height: AppSizing.space4),
                        Text(
                          title,
                          style: AppTextStyles.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSizing.space4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Text(
                                subtitle,
                                style: AppTextStyles.bodyMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (trailing case final trailing?) ...[
                              const SizedBox(width: AppSizing.space8),
                              trailing,
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (actionLabel != null) ...[
                const SizedBox(height: AppSizing.space12),
                AppButton(
                  label: actionLabel,
                  variant: AppButtonVariant.soft,
                  onPressed: onAction,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Property thumbnail stand-in.
///
/// TODO(backend): show the property image once a case carries one.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizing.iconButtonSize,
      height: AppSizing.iconButtonSize,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppSizing.radiusMd),
      ),
      child: const Icon(
        Icons.location_city_outlined,
        size: AppSizing.iconMd,
        color: AppColors.primary,
      ),
    );
  }
}
