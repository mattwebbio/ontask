import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/notifications_repository.dart';
import '../domain/notification_item.dart';

part 'notifications_provider.g.dart';

/// Triggers push permission request and device token registration.
/// Called once post-auth. Result is `AsyncValue<void>` — callers ignore the
/// value but can check for errors.
@riverpod
Future<void> registerDeviceToken(Ref ref) async {
  final repo = ref.read(notificationsRepositoryProvider);
  await repo.requestPermissionAndRegisterToken();
}

/// Fetches notification history. Async provider — callers use AsyncValue pattern.
/// Invalidate on NotificationCentreScreen open to refresh unread count.
@riverpod
Future<NotificationHistoryResult> notificationHistory(Ref ref) async {
  final repo = ref.read(notificationsRepositoryProvider);
  return repo.getNotificationHistory();
}
