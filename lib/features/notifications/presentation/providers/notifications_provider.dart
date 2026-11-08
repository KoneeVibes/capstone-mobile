import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/navigation/app_session.dart';
import '../../data/repositories/mock_notifications_repository.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';

/// A fresh mock per sign-in, seeded for the role (ADR 0031).
final notificationsRepositoryProvider =
    Provider.autoDispose<NotificationsRepository>(
      (ref) => MockNotificationsRepository(
        ref.watch(sessionProvider)?.role ?? AppRole.client,
      ),
    );

class NotificationsNotifier extends AsyncNotifier<List<AppNotification>> {
  @override
  Future<List<AppNotification>> build() async {
    if (ref.watch(sessionProvider) == null) return untilSignedIn();
    final result = await ref
        .watch(notificationsRepositoryProvider)
        .fetchNotifications();
    return result.unwrapOrThrow();
  }

  /// Opening the list reads everything in it, which clears the bell's dot.
  Future<void> markAllRead() async {
    final List<AppNotification> current;
    try {
      current = await future;
    } on Object {
      return; // The screen shows the load failure; nothing to mark.
    }
    if (!ref.mounted || current.every((item) => item.isRead)) return;
    final result = await ref
        .read(notificationsRepositoryProvider)
        .markAllRead();
    if (result.isOk && ref.mounted) {
      state = AsyncData([for (final item in current) item.markRead()]);
    }
  }
}

final notificationsProvider =
    AsyncNotifierProvider.autoDispose<
      NotificationsNotifier,
      List<AppNotification>
    >(NotificationsNotifier.new);

/// Whether the bell shows its dot.
final hasUnreadNotificationsProvider = Provider.autoDispose<bool>(
  (ref) =>
      ref.watch(notificationsProvider).value?.any((item) => !item.isRead) ??
      false,
);
