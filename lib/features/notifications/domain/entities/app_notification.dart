import 'package:equatable/equatable.dart';

/// What a notification is about, which picks its icon.
enum NotificationKind { assignment, update }

/// One entry in the signed-in user's notifications.
class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
  });

  final String id;
  final NotificationKind kind;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;

  AppNotification markRead() => AppNotification(
    id: id,
    kind: kind,
    title: title,
    body: body,
    createdAt: createdAt,
    isRead: true,
  );

  @override
  List<Object?> get props => [id, kind, title, body, createdAt, isRead];
}
