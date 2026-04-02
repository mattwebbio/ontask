import 'dart:io';
import 'package:push/push.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/api_client.dart';
import '../domain/notification_item.dart';

part 'notifications_repository.g.dart';

class NotificationsRepository {
  const NotificationsRepository({required this.apiClient});

  final ApiClient apiClient;

  /// Requests push permission and registers device token with the API.
  /// Call once after auth completes (not on every screen — over-requesting
  /// permission is a top reason users deny it permanently).
  /// CRITICAL: always check if (!mounted) before setState after await in callers.
  Future<void> requestPermissionAndRegisterToken() async {
    final granted = await Push.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (!granted) return;

    final token = await Push.instance.token;
    if (token == null) return;

    final environment = _resolveEnvironment();
    final platform = Platform.isIOS ? 'ios' : 'macos';

    await apiClient.dio.post<void>(
      '/v1/notifications/device-token',
      data: {
        'token': token,
        'platform': platform,
        'environment': environment,
      },
    );
  }

  /// Returns 'development' for debug builds, 'production' for release/profile.
  /// DEPLOY-4: TestFlight and App Store use production environment.
  String _resolveEnvironment() {
    // kReleaseMode covers TestFlight and App Store builds.
    // kDebugMode covers local simulator and device debug builds.
    const bool isRelease = bool.fromEnvironment('dart.vm.product');
    return isRelease ? 'production' : 'development';
  }

  /// Fetches the notification history for the current user.
  /// Returns notifications in reverse chronological order (server-sorted).
  /// AC: 1 — feeds NotificationCentreScreen.
  Future<NotificationHistoryResult> getNotificationHistory() async {
    final response = await apiClient.dio.get<Map<String, dynamic>>(
      '/v1/notifications',
    );
    final data = (response.data!['data'] as Map<String, dynamic>);
    final items = (data['notifications'] as List<dynamic>)
        .map((e) => _parseNotificationItem(e as Map<String, dynamic>))
        .toList();
    return NotificationHistoryResult(
      notifications: items,
      unreadCount: data['unreadCount'] as int,
    );
  }

  /// Marks all notifications as read server-side.
  Future<void> markAllRead() async {
    await apiClient.dio.patch<void>('/v1/notifications/read-all');
  }

  NotificationItem _parseNotificationItem(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      taskId: json['taskId'] as String?,
      readAt: json['readAt'] != null
          ? DateTime.parse(json['readAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Updates notification preference at any of the three levels (FR43):
  ///   scope='global' — all notifications on/off
  ///   scope='device' — per-device preference (pass deviceId)
  ///   scope='task'   — per-task preference (pass taskId)
  Future<void> setPreference({
    required String scope,
    String? deviceId,
    String? taskId,
    required bool enabled,
  }) async {
    await apiClient.dio.put<void>(
      '/v1/notifications/preferences',
      data: {
        'scope': scope,
        'deviceId': deviceId,
        'taskId': taskId,
        'enabled': enabled,
      },
    );
  }
}

@riverpod
NotificationsRepository notificationsRepository(Ref ref) {
  return NotificationsRepository(apiClient: ref.watch(apiClientProvider));
}
