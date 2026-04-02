import 'dart:io';
import 'package:live_activities/live_activities.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/api_client.dart';
import '../domain/live_activity_types.dart';

part 'live_activities_repository.g.dart';

/// Repository for managing Live Activities via the live_activities plugin.
///
/// CRITICAL: ALL calls to the live_activities plugin MUST be wrapped in
/// `if (Platform.isIOS)` guards. macOS does NOT support Live Activities.
/// The macOS build ignores the OnTaskLiveActivity extension target entirely.
/// ARCH-28: live_activities Flutter plugin bridges to OnTaskLiveActivity Swift extension.
class LiveActivitiesRepository {
  const LiveActivitiesRepository({required this.apiClient});

  final ApiClient apiClient;
  final _plugin = const LiveActivities();

  /// Initialises the live_activities plugin and registers the push token callback.
  ///
  /// Call once during app startup (after auth completes), guarded with Platform.isIOS.
  /// The plugin calls [onActivityUpdate] when the ActivityKit push token changes —
  /// we must re-POST the new token to the server (ARCH-28 background token refresh).
  Future<void> init({required String activityType, String? taskId}) async {
    if (!Platform.isIOS) return;
    await _plugin.init(appGroupId: 'group.com.ontaskhq.ontask');
    // TODO(impl): _plugin.activityUpdateStream.listen((update) {
    //   if (update.activityToken != null) {
    //     registerToken(
    //       taskId: taskId,
    //       activityType: activityType,
    //       pushToken: update.activityToken!,
    //     );
    //   }
    // });
  }

  /// Registers an ActivityKit push token with the server.
  ///
  /// Called when an activity starts and on background token refresh.
  /// POST /v1/live-activities/token — upserts on (userId, taskId, activityType).
  Future<void> registerToken({
    String? taskId,
    required String activityType,
    required String pushToken,
  }) async {
    if (!Platform.isIOS) return;
    // expiresAt: ActivityKit tokens expire with the activity (iOS max 8 hours).
    final expiresAt = DateTime.now().add(const Duration(hours: 8)).toUtc().toIso8601String();
    await apiClient.dio.post<void>(
      '/v1/live-activities/token',
      data: {
        'taskId': taskId,
        'activityType': activityType,
        'pushToken': pushToken,
        'expiresAt': expiresAt,
      },
    );
  }
}

@riverpod
LiveActivitiesRepository liveActivitiesRepository(Ref ref) {
  return LiveActivitiesRepository(apiClient: ref.watch(apiClientProvider));
}
