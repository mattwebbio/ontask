import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/strings.dart';
import '../domain/notification_item.dart';
import 'notifications_provider.dart';

/// In-app notification centre — shows recent notifications in reverse
/// chronological order with type icon and timestamp. (AC: 1, FR42, Story 8.5)
///
/// Opened from the bell icon in AppShell's navigation bar.
/// impl(8.5): On open, call markAllRead() to clear the badge.
class NotificationCentreScreen extends ConsumerWidget {
  const NotificationCentreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(notificationHistoryProvider);
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(AppStrings.notificationCentreTitle),
        // impl(8.5): trailing 'Mark all read' button → ref.read(notificationsRepositoryProvider).markAllRead()
        //            then ref.invalidate(notificationHistoryProvider)
      ),
      child: SafeArea(
        child: historyAsync.when(
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (e, _) => Center(
            child: Text(AppStrings.notificationCentreLoadError),
          ),
          data: (result) => result.notifications.isEmpty
              ? Center(child: Text(AppStrings.notificationCentreEmpty))
              : ListView.builder(
                  itemCount: result.notifications.length,
                  itemBuilder: (context, index) {
                    final item = result.notifications[index];
                    return _NotificationRow(item: item);
                  },
                ),
        ),
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.item});
  final NotificationItem item;

  @override
  Widget build(BuildContext context) {
    return CupertinoListTile(
      leading: Icon(_iconForType(item.type)),
      title: Text(item.title),
      subtitle: Text(item.body),
      additionalInfo: Text(_formatTimestamp(item.createdAt)),
      // impl(8.5): unread dot indicator — show filled circle when item.isUnread
      // impl(8.5): on tap → navigate based on item.type and item.taskId
      //            (reuse same routing logic as notification_handler.dart impl(8.5):)
    );
  }

  IconData _iconForType(String type) {
    return switch (type) {
      'reminder' || 'deadline_today' || 'deadline_tomorrow' => CupertinoIcons.clock,
      'stake_warning' => CupertinoIcons.exclamationmark_triangle,
      'charge_succeeded' => CupertinoIcons.creditcard,
      'verification_approved' => CupertinoIcons.checkmark_seal,
      'dispute_filed' || 'dispute_approved' || 'dispute_rejected' => CupertinoIcons.doc_text,
      'social_completion' => CupertinoIcons.person_2,
      'schedule_change' => CupertinoIcons.calendar_badge_plus,
      _ => CupertinoIcons.bell,
    };
  }

  String _formatTimestamp(DateTime createdAt) {
    // impl(8.5): Use relative time (e.g. "2h ago", "Yesterday") when
    //            time_format.dart utility is created (deferred from Stories 2.7/2.8).
    //            For now, format as HH:mm.
    final h = createdAt.hour.toString().padLeft(2, '0');
    final m = createdAt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
