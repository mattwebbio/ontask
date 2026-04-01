import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ontask/core/l10n/strings.dart';
import 'package:ontask/core/theme/app_theme.dart';
import 'package:ontask/features/commitment_contracts/presentation/lock_confirmation_screen.dart';
import 'package:ontask/features/commitment_contracts/presentation/widgets/commitment_ceremony_card.dart';

// Widget tests for LockConfirmationScreen and CommitmentCeremonyCard
// — Story 6.8 (AC: 1, 2).
//
// Uses MaterialApp.router with a minimal GoRouter that includes /chapter-break
// so context.push can succeed without a missing-route error when testing
// LockConfirmationScreen end-to-end.
//
// CommitmentCeremonyCard widget-level tests use plain MaterialApp for isolation.

// ── GoRouter factory ──────────────────────────────────────────────────────────

GoRouter _makeRouter({required Widget home}) {
  return GoRouter(
    initialLocation: '/lock',
    routes: [
      GoRoute(
        path: '/lock',
        builder: (_, __) => home,
      ),
      GoRoute(
        path: '/chapter-break',
        builder: (_, __) => const Scaffold(
          body: Center(child: Text('Chapter Break')),
        ),
      ),
    ],
  );
}

Widget _wrapWithRouter(Widget screen) {
  return ProviderScope(
    child: MaterialApp.router(
      theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
      routerConfig: _makeRouter(home: screen),
    ),
  );
}

// ── Test helper: default LockConfirmationScreen ───────────────────────────────

LockConfirmationScreen _makeLockScreen({
  String taskTitle = 'Test task',
  int stakeAmountCents = 5000,
  String charityName = 'Test Charity',
}) {
  return LockConfirmationScreen(
    taskId: 'task-1',
    taskTitle: taskTitle,
    stakeAmountCents: stakeAmountCents,
    charityName: charityName,
    charityId: 'charity-1',
    deadline: DateTime(2026, 5, 1, 14, 0),
  );
}

// ── Test helper: CommitmentCeremonyCard wrapper ───────────────────────────────

Widget _buildCeremonyCard({
  String taskTitle = 'Test task',
  int stakeAmountCents = 5000,
  String charityName = 'Test Charity',
  VoidCallback? onLock,
  bool isLoading = false,
}) {
  return MaterialApp(
    theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
    home: Scaffold(
      body: CommitmentCeremonyCard(
        taskTitle: taskTitle,
        stakeAmountCents: stakeAmountCents,
        charityName: charityName,
        deadline: DateTime(2026, 5, 1, 14, 0),
        onLock: onLock ?? () {},
        isLoading: isLoading,
      ),
    ),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Mock the platform channel for HapticFeedback so it does not throw
    // a MissingPluginException during tests.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async => null,
    );
  });

  group('LockConfirmationScreen (AC: 1, 2)', () {
    testWidgets('renders CommitmentCeremonyCard with task title and amount',
        (tester) async {
      await tester.pumpWidget(
        _wrapWithRouter(_makeLockScreen(
          taskTitle: 'Test task',
          stakeAmountCents: 5000,
          charityName: 'Test Charity',
        )),
      );
      await tester.pumpAndSettle();

      // Verify ceremony copy text is present (UX-DR32).
      expect(find.text(AppStrings.commitmentCeremonyCopy), findsOneWidget);
      // Verify formatted stake amount '$50' (5000 cents).
      expect(find.text(r'$50'), findsOneWidget);
      // Verify charity name is present.
      expect(find.text('Test Charity'), findsOneWidget);
      // Verify task title is present.
      expect(find.text('Test task'), findsOneWidget);
    });

    testWidgets('does not show a CupertinoNavigationBar back button',
        (tester) async {
      await tester.pumpWidget(
        _wrapWithRouter(_makeLockScreen()),
      );
      await tester.pumpAndSettle();

      // LockConfirmationScreen uses PopScope(canPop: false) and no
      // CupertinoNavigationBar — intentionally no back button (UX spec line 842).
      expect(find.byType(CupertinoNavigationBar), findsNothing);
      expect(
        find.byWidgetPredicate((w) => w is PopScope && w.canPop == false),
        findsOneWidget,
      );
    });
  });

  group('CommitmentCeremonyCard (AC: 1)', () {
    testWidgets(
        'tapping "Lock it in." fires animation and calls onLock after completion',
        (tester) async {
      bool lockCalled = false;

      await tester.pumpWidget(
        _buildCeremonyCard(onLock: () => lockCalled = true),
      );
      await tester.pump();

      // "Lock it in." button should be present.
      expect(find.text(AppStrings.stakeConfirmButton), findsOneWidget);

      // onLock should NOT be called before the button is tapped.
      expect(lockCalled, isFalse);

      // Tap the button — fires HapticFeedback.heavyImpact() + vault-close animation.
      await tester.tap(find.text(AppStrings.stakeConfirmButton));
      // Flush microtask queue so async _onLockTap proceeds past the
      // HapticFeedback.heavyImpact() await and calls _controller.forward().
      await tester.pump();
      await tester.pump();

      // Drive the 600ms vault-close animation to completion.
      await tester.pump(const Duration(milliseconds: 700));
      // Final pump to flush the AnimationStatus.completed callback.
      await tester.pump();

      // onLock must be called after animation completes — not immediately on tap.
      expect(lockCalled, isTrue);
    });

    testWidgets('shows CupertinoActivityIndicator when isLoading is true',
        (tester) async {
      await tester.pumpWidget(
        _buildCeremonyCard(isLoading: true),
      );
      await tester.pump();

      // Loading indicator is shown.
      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
      // "Lock it in." button is NOT shown while loading.
      expect(find.text(AppStrings.stakeConfirmButton), findsNothing);
    });

    testWidgets('renders commitment ceremony copy (UX-DR32)', (tester) async {
      await tester.pumpWidget(_buildCeremonyCard());
      await tester.pump();

      expect(find.text(AppStrings.commitmentCeremonyCopy), findsOneWidget);
      expect(find.text(AppStrings.commitmentCeremonyEyebrow), findsOneWidget);
    });
  });
}
