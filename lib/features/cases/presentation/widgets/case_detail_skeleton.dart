import 'package:flutter/material.dart';

import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_shimmer.dart';

/// Placeholder shown while a case loads.
///
/// Mirrors the detail layout for the role — the client's property header, the
/// case card with its rows and document tiles, and the pinned footer buttons —
/// so the real content lands in place.
class CaseDetailSkeleton extends StatelessWidget {
  const CaseDetailSkeleton({required this.forClient, super.key});

  /// Clients get the property header and one footer button; staff get two.
  final bool forClient;

  /// Clients do not see the Assignment row.
  int get _rowCount => forClient ? 4 : 5;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSizing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (forClient) ...[
                  const AppShimmer(child: _HeaderSkeleton()),
                  const SizedBox(height: AppSizing.space16),
                ],
                _CardSkeleton(rowCount: _rowCount, showMenu: !forClient),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizing.screenPadding,
            0,
            AppSizing.screenPadding,
            AppSizing.space16,
          ),
          child: AppShimmer(
            child: Row(
              children: [
                if (!forClient) ...[
                  const Expanded(child: _ButtonSkeleton()),
                  const SizedBox(width: AppSizing.space12),
                ],
                const Expanded(child: _ButtonSkeleton()),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Icon tile, two lines and a status pill.
class _HeaderSkeleton extends StatelessWidget {
  const _HeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        AppShimmerBox(
          width: AppSizing.iconButtonSize,
          height: AppSizing.iconButtonSize,
          radius: AppSizing.radiusMd,
        ),
        SizedBox(width: AppSizing.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppShimmerBox(width: 180, height: AppSizing.space16),
              SizedBox(height: AppSizing.space6),
              AppShimmerBox(width: 120),
            ],
          ),
        ),
        SizedBox(width: AppSizing.space8),
        AppShimmerBox(
          width: 72,
          height: AppSizing.chipHeight,
          radius: AppSizing.radiusPill,
        ),
      ],
    );
  }
}

/// The case card: heading (with the ⋮ for staff), rule, rows, document tiles.
class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton({required this.rowCount, required this.showMenu});

  final int rowCount;
  final bool showMenu;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizing.space20,
              vertical: AppSizing.space12,
            ),
            child: AppShimmer(
              child: SizedBox(
                height: AppSizing.iconButtonSize,
                child: Row(
                  children: [
                    const AppShimmerBox(width: 140, height: AppSizing.space16),
                    const Spacer(),
                    if (showMenu)
                      const AppShimmerBox(
                        width: AppSizing.space4,
                        height: AppSizing.iconMd,
                      ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(AppSizing.space20),
            child: AppShimmer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppShimmerBox(width: 80, height: AppSizing.space16),
                  const SizedBox(height: AppSizing.space16),
                  for (var i = 0; i < rowCount; i++) ...[
                    if (i != 0) ...[
                      const SizedBox(height: AppSizing.space12),
                      const Divider(),
                      const SizedBox(height: AppSizing.space12),
                    ],
                    const AppShimmerBox(width: 100),
                    const SizedBox(height: AppSizing.space8),
                    const AppShimmerBox(width: 190, height: AppSizing.space16),
                  ],
                  const SizedBox(height: AppSizing.space24),
                  const AppShimmerBox(width: 150, height: AppSizing.space16),
                  const SizedBox(height: AppSizing.space12),
                  const Row(
                    children: [
                      Expanded(child: _TileSkeleton()),
                      SizedBox(width: AppSizing.space8),
                      Expanded(child: _TileSkeleton()),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TileSkeleton extends StatelessWidget {
  const _TileSkeleton();

  @override
  Widget build(BuildContext context) {
    return const AppShimmerBox(
      height: AppSizing.buttonHeight,
      radius: AppSizing.radiusSm,
    );
  }
}

class _ButtonSkeleton extends StatelessWidget {
  const _ButtonSkeleton();

  @override
  Widget build(BuildContext context) {
    return const AppShimmerBox(
      height: AppSizing.buttonHeight,
      radius: AppSizing.radiusMd,
    );
  }
}
