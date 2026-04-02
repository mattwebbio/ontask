// Tests for NotificationCentreScreen widget.
// Uses fake provider override — follows pattern from list_settings_screen_test.dart.
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontask/core/l10n/strings.dart';
import 'package:ontask/features/notifications/domain/notification_item.dart';
import 'package:ontask/features/notifications/presentation/notification_centre_screen.dart';
import 'package:ontask/features/notifications/presentation/notifications_provider.dart';

void main() {
  group('NotificationCentreScreen', () {
    testWidgets('renders navigation bar title', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationHistoryProvider.overrideWith((_) async =>
                const NotificationHistoryResult(
                    notifications: [], unreadCount: 0)),
          ],
          child: const CupertinoApp(home: NotificationCentreScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.notificationCentreTitle), findsOneWidget);
    });

    testWidgets('loading state shows CupertinoActivityIndicator', (tester) async {
      final completer = Completer<NotificationHistoryResult>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationHistoryProvider.overrideWith((_) => completer.future),
          ],
          child: const CupertinoApp(home: NotificationCentreScreen()),
        ),
      );
      // Only pump once — do not settle — so loading state is visible
      await tester.pump();
      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
      // Complete the future to prevent pending timer assertion
      completer.complete(
          const NotificationHistoryResult(notifications: [], unreadCount: 0));
      await tester.pumpAndSettle();
    });

    testWidgets('empty state shows notificationCentreEmpty string', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationHistoryProvider.overrideWith((_) async =>
                const NotificationHistoryResult(
                    notifications: [], unreadCount: 0)),
          ],
          child: const CupertinoApp(home: NotificationCentreScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.notificationCentreEmpty), findsOneWidget);
    });

    testWidgets('with one notification item ListView renders', (tester) async {
      final item = NotificationItem(
        id: 'a0000000-0000-4000-8000-000000000001',
        type: 'reminder',
        title: 'Test Notification',
        body: 'Time to work on your task',
        taskId: null,
        readAt: null,
        createdAt: DateTime(2026, 4, 1, 10, 0),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationHistoryProvider.overrideWith((_) async =>
                NotificationHistoryResult(
                    notifications: [item], unreadCount: 1)),
          ],
          child: const CupertinoApp(home: NotificationCentreScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('Test Notification'), findsOneWidget);
    });

    testWidgets('error state shows notificationCentreLoadError string',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationHistoryProvider.overrideWith((_) async {
              throw Exception('Network error');
            }),
          ],
          child: const CupertinoApp(home: NotificationCentreScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.notificationCentreLoadError), findsOneWidget);
    });
  });
}
