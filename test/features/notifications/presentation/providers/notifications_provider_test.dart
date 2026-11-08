import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propertyintelmobileapp/core/navigation/app_session.dart';
import 'package:propertyintelmobileapp/features/notifications/presentation/providers/notifications_provider.dart';

void main() {
  ProviderContainer makeContainer(SessionUser? user) {
    final container = ProviderContainer(
      overrides: [sessionProvider.overrideWithValue(user)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('shows nothing while signed out', () async {
    final container = makeContainer(null)
      ..listen(notificationsProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);

    expect(container.read(notificationsProvider).isLoading, isTrue);
    expect(container.read(hasUnreadNotificationsProvider), isFalse);
  });

  test('seeds each role its own unread list', () async {
    final staff = makeContainer(
      const SessionUser(id: 'user-1', role: AppRole.staff),
    )..listen(hasUnreadNotificationsProvider, (_, _) {});
    final client = makeContainer(
      const SessionUser(id: 'user-2', role: AppRole.client),
    );

    final staffItems = await staff.read(notificationsProvider.future);
    final clientItems = await client.read(notificationsProvider.future);

    expect(staffItems.first.title, 'Saith Godwin Assigned');
    expect(
      clientItems.map((item) => item.title),
      isNot(contains('Saith Godwin Assigned')),
    );
    expect(staff.read(hasUnreadNotificationsProvider), isTrue);
  });

  test('marking all read clears the dot', () async {
    final container = makeContainer(
      const SessionUser(id: 'user-1', role: AppRole.staff),
    )..listen(hasUnreadNotificationsProvider, (_, _) {});
    await container.read(notificationsProvider.future);

    await container.read(notificationsProvider.notifier).markAllRead();

    expect(container.read(hasUnreadNotificationsProvider), isFalse);
    expect(
      container.read(notificationsProvider).value!.every((n) => n.isRead),
      isTrue,
    );
  });
}
