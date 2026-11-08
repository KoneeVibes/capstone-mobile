import 'package:clock/clock.dart';

import '../../../../core/navigation/app_session.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';

/// Mock: a seeded list held in memory, per role (ADR 0031).
///
/// TODO(backend): replace with a remote repository once the API has a
/// notifications endpoint.
class MockNotificationsRepository implements NotificationsRepository {
  MockNotificationsRepository(AppRole role)
    : _items = role.isStaff ? _staffSeed() : _clientSeed();

  List<AppNotification> _items;

  @override
  Future<Result<List<AppNotification>>> fetchNotifications() async =>
      Ok(List.unmodifiable(_items));

  @override
  Future<Result<void>> markAllRead() async {
    _items = [for (final item in _items) item.markRead()];
    return const Ok(null);
  }

  static DateTime _daysAgo(int days, int minutes) =>
      clock.now().subtract(Duration(days: days, minutes: minutes));

  /// The design's demo content.
  static List<AppNotification> _staffSeed() => [
    AppNotification(
      id: 'seed-staff-1',
      kind: NotificationKind.assignment,
      title: 'Saith Godwin Assigned',
      body: 'Block C, Ikoyi Crescent was assigned to you',
      createdAt: _daysAgo(2, 0),
    ),
    AppNotification(
      id: 'seed-staff-2',
      kind: NotificationKind.assignment,
      title: 'Search assigned successfully',
      body:
          'SLP-2291 has been assigned to Kolajo Mike. The staff member has '
          'been notified.',
      createdAt: _daysAgo(2, 10),
    ),
    AppNotification(
      id: 'seed-staff-3',
      kind: NotificationKind.update,
      title: 'Staff accepted assignment',
      body:
          'Kolajo Mike has accepted the assignment for SLP-2291. The search '
          'process can now begin.',
      createdAt: _daysAgo(2, 20),
    ),
    AppNotification(
      id: 'seed-staff-4',
      kind: NotificationKind.update,
      title: 'Search process started',
      body:
          'Kolajo Mike has started working on SLP-2291. The search is now in '
          'progress.',
      createdAt: _daysAgo(2, 30),
    ),
    AppNotification(
      id: 'seed-staff-5',
      kind: NotificationKind.assignment,
      title: 'New report submitted',
      body:
          'Kolajo Mike has submitted the land search report for SLP-2291. '
          'Review the report to proceed.',
      createdAt: _daysAgo(2, 40),
    ),
    AppNotification(
      id: 'seed-staff-6',
      kind: NotificationKind.update,
      title: 'Report awaiting review',
      body:
          'A new report for SLP-2291 is waiting for your review. Open the '
          'report to verify the submitted findings.',
      createdAt: _daysAgo(2, 50),
    ),
  ];

  static List<AppNotification> _clientSeed() => [
    AppNotification(
      id: 'seed-client-1',
      kind: NotificationKind.update,
      title: 'Search process started',
      body: 'Work has started on SLP-2291. The search is now in progress.',
      createdAt: _daysAgo(2, 0),
    ),
    AppNotification(
      id: 'seed-client-2',
      kind: NotificationKind.assignment,
      title: 'Search assigned',
      body: 'SLP-2291 has been assigned to a staff member.',
      createdAt: _daysAgo(2, 10),
    ),
    AppNotification(
      id: 'seed-client-3',
      kind: NotificationKind.update,
      title: 'Payment received',
      body: 'Your payment for SLP-2291 has been confirmed.',
      createdAt: _daysAgo(2, 20),
    ),
  ];
}
