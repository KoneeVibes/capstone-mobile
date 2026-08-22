import 'package:flutter/material.dart';

import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../domain/entities/case.dart';
import 'case_status_chip.dart';

/// One case card in the list.
class CaseListTile extends StatelessWidget {
  const CaseListTile({required this.value, required this.onTap, super.key});

  final Case value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSizing.radiusLg);

    return Material(
      color: AppColors.surface,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.all(AppSizing.space16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Initials only: an applicant is not a user account, so the API
              // carries no avatar for them.
              AppAvatar(initials: value.applicant.initials),
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
                            value.applicant.name,
                            style: AppTextStyles.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSizing.space8),
                        CaseStatusChip(status: value.status),
                      ],
                    ),
                    const SizedBox(height: AppSizing.space4),
                    Text(
                      value.summary,
                      style: AppTextStyles.bodyMedium,
                      // Two lines: the summary carries the property type and
                      // location, which will not fit on one line on a narrow
                      // phone and matter too much to truncate at word two.
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSizing.space12),
                    const Divider(),
                    const SizedBox(height: AppSizing.space12),
                    Text(
                      _assignment(value),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Who holds the case.
  ///
  /// Three states, not two: a case can be assigned to somebody whose name did
  /// not resolve — a staff member since deactivated, or a staff request that
  /// failed — and calling that "Unassigned" would be a lie the user could act
  /// on.
  static String _assignment(Case value) {
    final name = value.assignee?.fullName;
    if (name != null && name.isNotEmpty) return 'Assigned to $name';
    return value.isAssigned ? 'Assigned' : 'Unassigned';
  }
}
