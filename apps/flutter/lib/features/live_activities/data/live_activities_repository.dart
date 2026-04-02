import 'package:flutter/foundation.dart';
import 'package:live_activities/live_activities.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/api_client.dart';
import '../domain/live_activity_types.dart';

part 'live_activities_repository.g.dart';

/// Repository for managing Live Activities via the live_activities plugin.
///
/// CRITICAL: ALL calls to the live_activities plugin MUST be wrapped in
/// `if (defaultTargetPlatform != TargetPlatform.iOS)` guards.
/// macOS does NOT support Live Activities.
/// The macOS build ignores the OnTaskLiveActivity extension target entirely.
/// ARCH-28: live_activities Flutter plugin bridges to OnTaskLiveActivity Swift extension.
class LiveActivitiesRepository {
  LiveActivitiesRepository({
    required this.apiClient,
    LiveActivities? plugin,
  }) : _plugin = plugin ?? LiveActivities();

  final ApiClient apiClient;
  final LiveActivities _plugin;

  /// Initialises the live_activities plugin and registers the push token callback.
  ///
  /// Call once during app startup (after auth completes), guarded with iOS platform check.
  /// The plugin calls [onActivityUpdate] when the ActivityKit push token changes —
  /// we must re-POST the new token to the server (ARCH-28 background token refresh).
  Future<void> init({required String activityType, String? taskId}) async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
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
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
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

  /// Starts a task_timer Live Activity.
  ///
  /// [taskId] is stored in OnTaskActivityAttributes (static, not ContentState).
  /// [taskTitle] goes in ContentState.taskTitle.
  /// [elapsedSeconds] initial value — typically 0 or resumed elapsed.
  /// Returns the activityId string for later updates/end calls.
  ///
  /// ARCH-28: ALL plugin calls guarded with Platform.isIOS.
  Future<String?> startTaskTimerActivity({
    required String taskId,
    required String taskTitle,
    int elapsedSeconds = 0,
    double? stakeAmount,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return null;
    // activityType maps to OnTaskActivityAttributes static field (not ContentState)
    // ContentState fields mirror OnTaskActivityAttributes.ContentState in Swift.
    // Field names are camelCase to match Swift CodingKeys exactly.
    final activityId = await _plugin.createActivity({
      'taskTitle': taskTitle,
      'elapsedSeconds': elapsedSeconds,
      'deadlineTimestamp': null,
      'stakeAmount': stakeAmount,
      'activityStatus': 'active',
    });
    if (activityId != null) {
      await registerToken(
        taskId: taskId,
        activityType: LiveActivityType.taskTimer,
        pushToken: activityId, // Token delivered async via activityUpdateStream
      );
      // TODO(impl): Write active task data to App Group UserDefaults for WidgetKit.
      // widgetDataWriter.writeWidgetData(
      //   activeTaskTitle: taskTitle,
      //   activeElapsedSeconds: elapsedSeconds,
      //   scheduleHealth: 'healthy',
      //   todayTasks: [],
      // );
      // widgetDataWriter.reloadWidgets();
    }
    return activityId;
  }

  /// Starts a commitment_countdown Live Activity.
  ///
  /// Activates when deadline is within 2 hours (caller's responsibility to check).
  /// [deadlineTimestamp] is the deadline as a DateTime (serialised to ISO 8601).
  Future<String?> startCommitmentCountdownActivity({
    required String taskId,
    required String taskTitle,
    required DateTime deadlineTimestamp,
    double? stakeAmount,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return null;
    final activityId = await _plugin.createActivity({
      'taskTitle': taskTitle,
      'elapsedSeconds': null,
      'deadlineTimestamp': deadlineTimestamp.toIso8601String(),
      'stakeAmount': stakeAmount,
      'activityStatus': 'active',
    });
    if (activityId != null) {
      await registerToken(
        taskId: taskId,
        activityType: LiveActivityType.commitmentCountdown,
        pushToken: activityId,
      );
    }
    return activityId;
  }

  /// Starts a watch_mode Live Activity.
  ///
  /// Watch Mode is iOS-only (UX-DR10). All calls guarded inside this method.
  /// The activity uses activityStatus: 'watchMode' to distinguish it from
  /// task_timer in the Swift extension's branching logic.
  ///
  /// [taskId] — stored in OnTaskActivityAttributes (static field).
  /// [taskTitle] — shown in Dynamic Island expanded + Lock Screen.
  /// [deadlineTimestamp] — optional; set if task has a commitment deadline.
  /// [stakeAmount] — optional; set if task has a financial stake.
  /// Returns activityId for later `updateElapsedSeconds` / `endActivity` calls.
  Future<String?> startWatchModeActivity({
    required String taskId,
    required String taskTitle,
    DateTime? deadlineTimestamp,
    double? stakeAmount,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return null;
    final activityId = await _plugin.createActivity({
      'taskTitle': taskTitle,
      'elapsedSeconds': 0,
      'deadlineTimestamp': deadlineTimestamp?.toIso8601String(),
      'stakeAmount': stakeAmount,
      'activityStatus': 'watchMode', // Maps to Status.watchMode in Swift CodingKeys
    });
    if (activityId != null) {
      await registerToken(
        taskId: taskId,
        activityType: LiveActivityType.watchMode,
        pushToken: activityId,
      );
    }
    return activityId;
  }

  /// Updates the elapsed seconds for a running task_timer activity.
  ///
  /// Called periodically from the Flutter timer (not on every second — only on
  /// meaningful updates to avoid excessive plugin calls).
  Future<void> updateElapsedSeconds({
    required String activityId,
    required int elapsedSeconds,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    await _plugin.updateActivity(activityId, {'elapsedSeconds': elapsedSeconds});
  }

  /// Ends any Live Activity by ID with final status.
  ///
  /// [finalStatus] must be 'completed' or 'failed' — maps to Status enum.
  Future<void> endActivity({
    required String activityId,
    String finalStatus = 'completed',
  }) async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    await _plugin.endActivity(activityId);
    // TODO(impl): Clear active task data in App Group UserDefaults after activity ends.
    // widgetDataWriter.writeWidgetData(
    //   activeTaskTitle: null,
    //   activeElapsedSeconds: null,
    //   scheduleHealth: 'healthy',
    //   todayTasks: [],
    // );
    // widgetDataWriter.reloadWidgets();
  }
}

@riverpod
LiveActivitiesRepository liveActivitiesRepository(Ref ref) {
  return LiveActivitiesRepository(apiClient: ref.watch(apiClientProvider));
}
