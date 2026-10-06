import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/app_bottom_nav.dart';

/// A role's tabs. [tabs] order must match the shell route's branch order.
///
/// A branch in [hiddenBranches] keeps its route — the redirect guards it — but
/// loses its tab.
class AppShell extends StatelessWidget {
  const AppShell({
    required this.navigationShell,
    required this.tabs,
    this.hiddenBranches = const {},
    super.key,
  });

  final StatefulNavigationShell navigationShell;
  final List<AppBottomNavItem> tabs;
  final Set<int> hiddenBranches;

  /// The Staff tab's index in [staffTabs], hidden from roles that cannot
  /// list staff.
  static const staffMembersBranch = 2;

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
    // Bottom-nav position -> branch index.
    final branches = [
      for (var i = 0; i < tabs.length; i++)
        if (!hiddenBranches.contains(i)) i,
    ];
    // A hidden branch is only open until the redirect moves off it.
    final position = branches.indexOf(current);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNav(
        items: [for (final i in branches) tabs[i]],
        currentIndex: position < 0 ? 0 : position,
        // Re-tapping the open tab returns it to its first screen.
        onSelected: (index) {
          final branch = branches[index];
          navigationShell.goBranch(
            branch,
            initialLocation: branch == current,
          );
        },
      ),
    );
  }
}
