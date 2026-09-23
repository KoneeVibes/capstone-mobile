import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/app_bottom_nav.dart';

/// The staff tabs. Item order must match the router's branch order.
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const _items = [
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
  ];

  @override
  Widget build(BuildContext context) {
    final current = navigationShell.currentIndex;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNav(
        items: _items,
        currentIndex: current,
        // Re-tapping the open tab returns it to its first screen.
        onSelected: (index) =>
            navigationShell.goBranch(index, initialLocation: index == current),
      ),
    );
  }
}
