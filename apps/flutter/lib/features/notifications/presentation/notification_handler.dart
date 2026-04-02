import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_handler.g.dart';

// ── Notification tap handler ──────────────────────────────────────────────────
// Handles tap on delivered push notifications (reminder, deadline, stake_warning).
// data.taskId → navigate to task detail or today tab.
// Called once after app launch; subscribes to the push tap stream.
// CRITICAL: check if (!mounted) before setState() after any async work.
// CRITICAL: Platform.isIOS / Platform.isMacOS guard not needed here — push
//   package abstracts platform difference for remote push notifications.

@riverpod
class NotificationHandler extends _$NotificationHandler {
  @override
  void build() {
    // impl(8.3): subscribe to Push.instance.onNotificationTap
    // impl(8.3): on tap, extract data['taskId'] and data['type']
    // impl(8.3): use GoRouter or Navigator to push task detail route
    // impl(8.3): type 'stake_warning'         → task detail with stake section visible
    // impl(8.3): type 'charge_succeeded'      → task detail (show billing history or task card)
    // impl(8.3): type 'verification_approved' → task detail (proof accepted state)
    // impl(8.3): type 'dispute_filed'         → task detail (dispute pending state)
    // impl(8.3): type 'dispute_approved'      → task detail (stake cancelled state)
    // impl(8.3): type 'dispute_rejected'      → task detail or billing history
    // impl(8.4): type 'social_completion'  → today tab or shared list view showing completed task
    // impl(8.4): type 'schedule_change'    → today tab with ScheduleChangeBannerVisible triggered
    //            NOTE: on 'schedule_change' tap, call:
    //              ref.read(scheduleChangeBannerVisibleProvider.notifier).dismiss() — NO,
    //              actually do NOT dismiss; instead invalidate scheduleChangesProvider so
    //              banner re-evaluates from fresh data, then navigate to Today tab.
    //            NOTE: ScheduleChangeBannerVisible is in:
    //              apps/flutter/lib/features/today/presentation/schedule_change_provider.dart
    //
    // Example subscription pattern:
    //   final sub = Push.instance.onNotificationTap.listen((notification) {
    //     final data = notification.data;
    //     final taskId = data?['taskId'] as String?;
    //     final type = data?['type'] as String?;
    //     if (taskId == null) return;
    //     // Navigate to task detail — use GoRouter context from ProviderScope or
    //     // a GlobalKey<NavigatorState> registered at app root.
    //   });
    //   ref.onDispose(sub.cancel);
  }
}
