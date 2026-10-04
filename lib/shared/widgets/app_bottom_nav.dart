import 'package:flutter/material.dart';

import '../../core/sizing/app_sizing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// One tab in an [AppBottomNav].
class AppBottomNavItem {
  /// Creates a tab. [selectedIcon] is usually the filled form of [icon].
  const AppBottomNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  /// The text under the icon, supplied by the shell that owns the tabs.
  final String label;

  /// Shown while the tab is not selected.
  final IconData icon;

  /// Shown while the tab is selected.
  final IconData selectedIcon;
}

/// Flat bottom bar: the selected tab is a filled icon and a blue label.
///
/// Stateless — the caller owns which tab is open, normally a go_router
/// `StatefulNavigationShell` (see `AppShell`).
class AppBottomNav extends StatelessWidget {
  /// Creates the bar. [currentIndex] must be a valid index into [items].
  const AppBottomNav({
    required this.items,
    required this.currentIndex,
    required this.onSelected,
    super.key,
  });

  /// The tabs, left to right.
  final List<AppBottomNavItem> items;

  /// The selected tab.
  final int currentIndex;

  /// Called with the tapped tab's index, including the one already open.
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.border,
            width: AppSizing.borderWidth,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: AppSizing.bottomNavHeight,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _NavButton(
                    item: items[i],
                    selected: i == currentIndex,
                    onTap: () => onSelected(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final AppBottomNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textSecondary;

    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? item.selectedIcon : item.icon,
              size: AppSizing.iconLg,
              color: color,
            ),
            const SizedBox(height: AppSizing.space4),
            Text(
              item.label,
              style: AppTextStyles.navLabel.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
