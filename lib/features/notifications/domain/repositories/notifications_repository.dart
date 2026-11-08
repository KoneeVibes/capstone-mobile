import '../../../../core/utils/result.dart';
import '../entities/app_notification.dart';

/// The signed-in user's notifications, newest first.
abstract class NotificationsRepository {
  Future<Result<List<AppNotification>>> fetchNotifications();

  Future<Result<void>> markAllRead();
}
