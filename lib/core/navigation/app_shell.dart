import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/app_bottom_nav.dart';

/// A role's tabs. [tabs] order must match the shell route's branch order.
class AppShell extends StatelessWidget {
  const AppShell({
    required this.navigationShell,
    required this.tabs,
    super.key,
  });

  final StatefulNavigationShell navigationShell;
  final List<AppBottomNavItem> tabs;

  static const staffTabs = [
    AppBottomNavItem(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
    ),
    AppBottomNavItem(
      label: 'Cases',
      icon: Icons.inbox_outlined,
      selectedIcon: Icons.inbox,
    ),
    AppBottomNavItem(
      label: 'Staff',
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
    ),
    _profileTab,
  ];

  static const clientTabs = [
    AppBottomNavItem(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
    ),
    AppBottomNavItem(
      label: 'Search',
      icon: Icons.search,
      selectedIcon: Icons.search,
    ),
    AppBottomNavItem(
      label: 'Cases',
      icon: Icons.access_time,
      selectedIcon: Icons.access_time_filled,
    ),
    _profileTab,
  ];

  static const _profileTab = AppBottomNavItem(
    label: 'Profile',
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
  );

  @override
  Widget build(BuildContext context) {
    assert(
      tabs.length == navigationShell.route.branches.length,
      'Every shell branch needs exactly one tab, in the same order.',
    );
    final current = navigationShell.currentIndex;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNav(
        items: tabs,
        currentIndex: current,
        // Re-tapping the open tab returns it to its first screen.
        onSelected: (index) =>
            navigationShell.goBranch(index, initialLocation: index == current),
      ),
    );
  }
}
