import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/sizing/app_sizing.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/notifications_provider.dart';

/// The bell in the home and profile headers, with a dot while anything is
/// unread. The router hands it to those screens (ADR 0031).
class NotificationBell extends ConsumerWidget {
  const NotificationBell({required this.routeName, super.key});

  /// The role's notifications screen.
  final String routeName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasUnread = ref.watch(hasUnreadNotificationsProvider);

    return IconButton(
      tooltip: hasUnread ? 'Notifications, unread' : 'Notifications',
      onPressed: () => context.pushNamed(routeName),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(
            Icons.notifications,
            size: AppSizing.iconLg,
            color: AppColors.primaryBright,
          ),
          if (hasUnread)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: AppSizing.unreadDot,
                height: AppSizing.unreadDot,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
