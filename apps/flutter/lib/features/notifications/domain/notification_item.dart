// Domain model for a single in-app notification history item.
// Maps to GET /v1/notifications response array element.
// No freezed — simple immutable class (consistent with other domain models in this project
// that do not require copy/equality beyond basic == check).
class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.taskId,
    this.readAt,
    required this.createdAt,
  });

  final String id;
  final String type;          // matches data.type values from push payload
  final String title;
  final String body;
  final String? taskId;
  final DateTime? readAt;     // null = unread
  final DateTime createdAt;

  bool get isUnread => readAt == null;
}

class NotificationHistoryResult {
  const NotificationHistoryResult({
    required this.notifications,
    required this.unreadCount,
  });
  final List<NotificationItem> notifications;
  final int unreadCount;
}
