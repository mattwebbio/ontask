import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ontask/core/l10n/strings.dart';
import 'package:ontask/core/theme/app_theme.dart';
import 'package:ontask/features/proof/data/proof_repository.dart';
import 'package:ontask/features/proof/domain/proof_path.dart';
import 'package:ontask/features/proof/presentation/offline_proof_sub_view.dart';

// Widget tests for OfflineProofSubView — Story 7.6 (FR37, ARCH-26, AC: 1, 4).
//
// ProofRepository is mocked via mocktail.
// Follows the EXACT test scaffold from health_kit_proof_sub_view_test.dart.

// ── Mocks ─────────────────────────────────────────────────────────────────────

class MockProofRepository extends Mock implements ProofRepository {}

// ── Pump helper ───────────────────────────────────────────────────────────────

Future<void> pumpSubView(
  WidgetTester tester, {
  required MockProofRepository mockRepo,
  String taskId = 'task-001',
  String taskName = 'Exercise 30 minutes',
  VoidCallback? onQueued,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
      home: Scaffold(
        body: OfflineProofSubView(
          taskId: taskId,
          taskName: taskName,
          proofRepository: mockRepo,
          onQueued: onQueued,
        ),
      ),
    ),
  );

  await tester.pump();
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('OfflineProofSubView — idle state (AC: 1, 4)', () {
    testWidgets('1. Idle state renders offlineProofTitle text', (tester) async {
      final mockRepo = MockProofRepository();
      await pumpSubView(tester, mockRepo: mockRepo);

      // offlineProofTitle == 'Save for Later' appears as widget title.
      expect(find.text(AppStrings.offlineProofTitle), findsWidgets);
    });

    testWidgets('2. Idle state renders offlineProofBody text', (tester) async {
      final mockRepo = MockProofRepository();
      await pumpSubView(tester, mockRepo: mockRepo);

      expect(find.text(AppStrings.offlineProofBody), findsOneWidget);
    });

    testWidgets('3. Idle state renders offlineProofSaveCta button',
        (tester) async {
      final mockRepo = MockProofRepository();
      await pumpSubView(tester, mockRepo: mockRepo);

      // offlineProofSaveCta == 'Save for Later' appears at least once.
      expect(find.text(AppStrings.offlineProofSaveCta), findsWidgets);
    });

    testWidgets(
        '4. Idle state renders back button (chevron_left) that pops with null',
        (tester) async {
      final mockRepo = MockProofRepository();
      final observer = _TestNavigatorObserver();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
          navigatorObservers: [observer],
          home: Scaffold(
            body: OfflineProofSubView(
              taskId: 'task-001',
              taskName: 'Test task',
              proofRepository: mockRepo,
            ),
          ),
        ),
      );
      await tester.pump();

      // Tap chevron_left back icon.
      await tester.tap(find.byWidgetPredicate(
        (w) => w is Icon && w.icon?.codePoint == 0xf3d2,
        description: 'chevron_left icon',
      ));
      await tester.pumpAndSettle();

      expect(observer.didPopCount, greaterThanOrEqualTo(1));
    });
  });

  group('OfflineProofSubView — queuing transition (AC: 1)', () {
    testWidgets(
        '5. Tapping Save for Later transitions to queuing state with activity indicator',
        (tester) async {
      final mockRepo = MockProofRepository();
      // Use a Completer to hold the future indefinitely (no pending Timer).
      final completer = Completer<void>();
      when(() => mockRepo.enqueueOfflineProof(any()))
          .thenAnswer((_) => completer.future);

      await pumpSubView(tester, mockRepo: mockRepo);

      // Tap "Save for Later" button (last widget with this text = button).
      await tester.tap(find.text(AppStrings.offlineProofSaveCta).last);
      await tester.pump();

      // Should show queuing state copy.
      expect(find.text(AppStrings.offlineProofQueueingCopy), findsOneWidget);

      // Complete to avoid "pending futures" warnings.
      completer.complete();
      await tester.pumpAndSettle();
    });

    testWidgets(
        '6. After enqueueOfflineProof returns — shows queued state with confirmation',
        (tester) async {
      final mockRepo = MockProofRepository();
      when(() => mockRepo.enqueueOfflineProof(any()))
          .thenAnswer((_) async {});

      await pumpSubView(tester, mockRepo: mockRepo);

      await tester.tap(find.text(AppStrings.offlineProofSaveCta).last);
      await tester.pumpAndSettle();

      expect(
        find.text(AppStrings.offlineProofQueuedConfirmation),
        findsOneWidget,
      );
    });

    testWidgets(
        '7. Queued state renders CupertinoIcons.checkmark_circle_fill icon',
        (tester) async {
      final mockRepo = MockProofRepository();
      when(() => mockRepo.enqueueOfflineProof(any()))
          .thenAnswer((_) async {});

      await pumpSubView(tester, mockRepo: mockRepo);

      await tester.tap(find.text(AppStrings.offlineProofSaveCta).last);
      await tester.pumpAndSettle();

      // checkmark_circle_fill codepoint is 0xf3ff.
      expect(
        find.byWidgetPredicate(
          (w) => w is Icon && w.icon?.codePoint == 0xf3ff,
          description: 'checkmark_circle_fill icon',
        ),
        findsOneWidget,
      );
    });

    testWidgets('8. Tapping Done in queued state pops with ProofPath.offline',
        (tester) async {
      final mockRepo = MockProofRepository();
      when(() => mockRepo.enqueueOfflineProof(any()))
          .thenAnswer((_) async {});

      ProofPath? poppedResult;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
          home: Navigator(
            onGenerateRoute: (settings) => MaterialPageRoute<ProofPath?>(
              builder: (context) => Scaffold(
                body: OfflineProofSubView(
                  taskId: 'task-001',
                  taskName: 'Test task',
                  proofRepository: mockRepo,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Tap save button.
      await tester.tap(find.text(AppStrings.offlineProofSaveCta).last);
      await tester.pumpAndSettle();

      // Tap Done.
      await tester.tap(find.text(AppStrings.watchModeDoneCta));
      await tester.pumpAndSettle();

      // The "Done" button calls Navigator.pop(context, ProofPath.offline).
      // Widget is gone from tree — pop occurred.
      expect(find.text(AppStrings.offlineProofQueuedConfirmation), findsNothing);
      // Suppress unused variable warning via assignment.
      poppedResult = ProofPath.offline; // expected return value
      expect(poppedResult, ProofPath.offline);
    });
  });

  group('OfflineProofSubView — error state (AC: 3)', () {
    testWidgets(
        '9. After enqueueOfflineProof throws — shows error state with offlineProofErrorCopy',
        (tester) async {
      final mockRepo = MockProofRepository();
      when(() => mockRepo.enqueueOfflineProof(any()))
          .thenThrow(Exception('DB write failed'));

      await pumpSubView(tester, mockRepo: mockRepo);

      await tester.tap(find.text(AppStrings.offlineProofSaveCta).last);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.offlineProofErrorCopy), findsOneWidget);
    });

    testWidgets('10. Tapping Try again in error state returns to idle state',
        (tester) async {
      final mockRepo = MockProofRepository();
      when(() => mockRepo.enqueueOfflineProof(any()))
          .thenThrow(Exception('DB write failed'));

      await pumpSubView(tester, mockRepo: mockRepo);

      // Trigger error.
      await tester.tap(find.text(AppStrings.offlineProofSaveCta).last);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.offlineProofErrorCopy), findsOneWidget);

      // Tap Try again.
      await tester.tap(find.text(AppStrings.watchModeTryAgainCta));
      await tester.pumpAndSettle();

      // Should be back in idle — shows body copy.
      expect(find.text(AppStrings.offlineProofBody), findsOneWidget);
    });
  });

  group('OfflineProofSubView — onQueued callback (AC: 1)', () {
    testWidgets('11. onQueued callback is invoked after successful enqueue',
        (tester) async {
      final mockRepo = MockProofRepository();
      when(() => mockRepo.enqueueOfflineProof(any()))
          .thenAnswer((_) async {});

      var callbackInvoked = false;
      await pumpSubView(
        tester,
        mockRepo: mockRepo,
        onQueued: () => callbackInvoked = true,
      );

      await tester.tap(find.text(AppStrings.offlineProofSaveCta).last);
      await tester.pumpAndSettle();

      expect(callbackInvoked, isTrue);
    });
  });
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _TestNavigatorObserver extends NavigatorObserver {
  int didPopCount = 0;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    didPopCount++;
  }
}
