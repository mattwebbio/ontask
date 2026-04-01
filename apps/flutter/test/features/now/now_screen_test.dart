import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontask/core/l10n/strings.dart';
import 'package:ontask/core/theme/app_theme.dart';
import 'package:ontask/features/auth/domain/auth_result.dart';
import 'package:ontask/features/auth/presentation/auth_provider.dart';
import 'package:ontask/features/now/domain/now_task.dart';
import 'package:ontask/features/now/domain/proof_mode.dart';
import 'package:ontask/features/now/presentation/now_provider.dart';
import 'package:ontask/features/now/presentation/now_screen.dart';
import 'package:ontask/features/now/presentation/widgets/commitment_row.dart';
import 'package:ontask/features/now/presentation/widgets/now_card_skeleton.dart';
import 'package:ontask/features/now/presentation/widgets/now_empty_state.dart';
import 'package:ontask/features/now/presentation/widgets/now_task_card.dart';
import 'package:ontask/features/now/presentation/widgets/proof_mode_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  final testTask = NowTask(
    id: 'task-1',
    title: 'Buy groceries',
    notes: 'Milk, eggs, bread',
    dueDate: DateTime(2026, 4, 1, 14, 0),
    listId: 'list-1',
    listName: 'Personal',
    assignorName: null,
    stakeAmountCents: null,
    proofMode: ProofMode.standard,
    createdAt: DateTime(2026, 3, 30),
    updatedAt: DateTime(2026, 3, 30),
  );

  final stakedTask = NowTask(
    id: 'task-2',
    title: 'Morning workout',
    dueDate: DateTime(2026, 4, 1, 9, 0),
    listName: 'Fitness',
    assignorName: null,
    stakeAmountCents: 2500,
    proofMode: ProofMode.photo,
    createdAt: DateTime(2026, 3, 30),
    updatedAt: DateTime(2026, 3, 30),
  );

  Widget buildScreen({NowTask? task, bool loading = false}) {
    return ProviderScope(
      overrides: [
        authStateProvider.overrideWithValue(
          const AuthResult.authenticated(userId: 'user_1', provider: 'email'),
        ),
        nowProvider.overrideWith(
          () => _FakeNowNotifier(task, loading: loading),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
        home: const NowScreen(),
      ),
    );
  }

  Widget buildCard({required NowTask task, VoidCallback? onComplete}) {
    return MaterialApp(
      theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
      home: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: NowTaskCard(task: task, onComplete: onComplete),
          ),
        ),
      ),
    );
  }

  group('NowScreen', () {
    testWidgets('shows skeleton initially during shimmer animation',
        (tester) async {
      await tester.pumpWidget(buildScreen(task: testTask));
      // Pump just one frame -- the 800ms skeleton delay hasn't completed
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(NowCardSkeleton), findsOneWidget);

      // After settling, skeleton should be gone
      await tester.pumpAndSettle();
      expect(find.byType(NowCardSkeleton), findsNothing);
    });

    testWidgets('shows task card after data loads', (tester) async {
      await tester.pumpWidget(buildScreen(task: testTask));
      await tester.pumpAndSettle();

      expect(find.byType(NowTaskCard), findsOneWidget);
      expect(find.text('Buy groceries'), findsOneWidget);
    });

    testWidgets('shows empty state when no current task', (tester) async {
      await tester.pumpWidget(buildScreen(task: null));
      await tester.pumpAndSettle();

      expect(find.byType(NowEmptyState), findsOneWidget);
      expect(find.text(AppStrings.nowEmptyTitle), findsOneWidget);
    });
  });

  group('NowTaskCard', () {
    testWidgets('renders task title in serif font', (tester) async {
      await tester.pumpWidget(buildCard(task: testTask));
      await tester.pumpAndSettle();

      final titleFinder = find.text('Buy groceries');
      expect(titleFinder, findsOneWidget);

      final titleWidget = tester.widget<Text>(titleFinder);
      expect(titleWidget.style?.fontFamily, isNotNull);
      expect(titleWidget.style?.fontSize, 28);
      expect(titleWidget.style?.fontWeight, FontWeight.w600);
    });

    testWidgets('renders attribution text', (tester) async {
      await tester.pumpWidget(buildCard(task: testTask));
      await tester.pumpAndSettle();

      // listName is set, so should show "From Personal"
      expect(find.text('From Personal'), findsOneWidget);
    });

    testWidgets('renders default attribution when no list', (tester) async {
      final noListTask = NowTask(
        id: 'task-3',
        title: 'Quick errand',
        createdAt: DateTime(2026, 3, 30),
        updatedAt: DateTime(2026, 3, 30),
      );
      await tester.pumpWidget(buildCard(task: noListTask));
      await tester.pumpAndSettle();

      expect(
        find.text(AppStrings.nowCardAttribution),
        findsOneWidget,
      );
    });

    testWidgets('shows stake row when stakeAmountCents present',
        (tester) async {
      await tester.pumpWidget(buildCard(task: stakedTask));
      await tester.pumpAndSettle();

      expect(find.text('\$25'), findsOneWidget);
      expect(find.text(AppStrings.nowCardStakeLabel), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.lock), findsOneWidget);
    });

    testWidgets('hides stake row when stakeAmountCents is null',
        (tester) async {
      await tester.pumpWidget(buildCard(task: testTask));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.nowCardStakeLabel), findsNothing);
      expect(find.byIcon(CupertinoIcons.lock), findsNothing);
    });

    testWidgets('renders standard proof mode CTA (Mark done)',
        (tester) async {
      await tester.pumpWidget(buildCard(task: testTask));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.nowCardMarkDone), findsOneWidget);
    });

    testWidgets('renders photo proof mode CTA (Submit proof)',
        (tester) async {
      final photoTask = NowTask(
        id: 'task-photo',
        title: 'Take photo',
        proofMode: ProofMode.photo,
        createdAt: DateTime(2026, 3, 30),
        updatedAt: DateTime(2026, 3, 30),
      );
      await tester.pumpWidget(buildCard(task: photoTask));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.nowCardSubmitProof), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.camera), findsAtLeast(1));
    });

    testWidgets('renders Watch Mode CTA', (tester) async {
      final watchTask = NowTask(
        id: 'task-watch',
        title: 'Study session',
        proofMode: ProofMode.watchMode,
        createdAt: DateTime(2026, 3, 30),
        updatedAt: DateTime(2026, 3, 30),
      );
      await tester.pumpWidget(buildCard(task: watchTask));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.nowCardStartWatchMode), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.eye), findsAtLeast(1));
    });

    testWidgets('renders HealthKit CTA', (tester) async {
      // Story 7.5: ProofMode.healthKit now shows nowCardProofHealthKit ("HealthKit")
      // with a heart icon, and opens ProofCaptureModal (not marks done directly).
      final hkTask = NowTask(
        id: 'task-hk',
        title: 'Go for a run',
        proofMode: ProofMode.healthKit,
        createdAt: DateTime(2026, 3, 30),
        updatedAt: DateTime(2026, 3, 30),
      );
      await tester.pumpWidget(buildCard(task: hkTask));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.nowCardProofHealthKit), findsAtLeast(1));
      expect(find.byIcon(CupertinoIcons.heart), findsAtLeast(1));
    });

    testWidgets('renders calendar event (no CTA)', (tester) async {
      final calTask = NowTask(
        id: 'task-cal',
        title: 'Team meeting',
        proofMode: ProofMode.calendarEvent,
        createdAt: DateTime(2026, 3, 30),
        updatedAt: DateTime(2026, 3, 30),
      );
      await tester.pumpWidget(buildCard(task: calTask));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.nowCardMarkDone), findsNothing);
      expect(find.text(AppStrings.nowCardSubmitProof), findsNothing);
      expect(find.text(AppStrings.nowCardStartWatchMode), findsNothing);
    });

    testWidgets('VoiceOver semantics label includes all segments',
        (tester) async {
      await tester.pumpWidget(buildCard(task: stakedTask));
      await tester.pumpAndSettle();

      // Find the Semantics widget that wraps the NowTaskCard
      final semanticsFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label != null &&
            widget.properties.label!.contains('Morning workout'),
      );
      expect(semanticsFinder, findsOneWidget);

      final semanticsWidget = tester.widget<Semantics>(semanticsFinder);
      final label = semanticsWidget.properties.label!;
      expect(label, contains('Morning workout'));
      expect(label, contains('from Fitness'));
      expect(label, contains('\$25 staked'));
      expect(label, contains('Photo proof'));
    });

    testWidgets('VoiceOver semantics label minimal (no extras)',
        (tester) async {
      final minTask = NowTask(
        id: 'task-min',
        title: 'Simple task',
        createdAt: DateTime(2026, 3, 30),
        updatedAt: DateTime(2026, 3, 30),
      );
      await tester.pumpWidget(buildCard(task: minTask));
      await tester.pumpAndSettle();

      final semanticsFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label != null &&
            widget.properties.label!.contains('Simple task'),
      );
      expect(semanticsFinder, findsOneWidget);

      final semanticsWidget = tester.widget<Semantics>(semanticsFinder);
      final label = semanticsWidget.properties.label!;
      expect(label, 'Simple task');
      expect(label, isNot(contains('from')));
      expect(label, isNot(contains('staked')));
    });

    testWidgets('Dynamic Island safe area padding via SafeArea',
        (tester) async {
      // NowScreen uses SafeArea which handles Dynamic Island padding
      await tester.pumpWidget(buildScreen(task: testTask));
      await tester.pumpAndSettle();

      // Verify SafeArea is present in the widget tree
      expect(find.byType(SafeArea), findsOneWidget);
    });
  });

  group('ProofModeIndicator', () {
    Widget buildIndicator(ProofMode mode) {
      return MaterialApp(
        theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
        home: Scaffold(
          body: ProofModeIndicator(
            proofMode: mode,
            textColor: const Color(0xFF000000),
          ),
        ),
      );
    }

    testWidgets('standard mode renders empty widget', (tester) async {
      await tester.pumpWidget(buildIndicator(ProofMode.standard));
      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('photo mode shows camera icon', (tester) async {
      await tester.pumpWidget(buildIndicator(ProofMode.photo));
      expect(find.byIcon(CupertinoIcons.camera), findsOneWidget);
      expect(find.text(AppStrings.nowCardProofPhoto), findsOneWidget);
    });

    testWidgets('watchMode shows eye icon', (tester) async {
      await tester.pumpWidget(buildIndicator(ProofMode.watchMode));
      expect(find.byIcon(CupertinoIcons.eye), findsOneWidget);
      expect(find.text(AppStrings.nowCardProofWatchMode), findsOneWidget);
    });

    testWidgets('healthKit shows heart icon', (tester) async {
      await tester.pumpWidget(buildIndicator(ProofMode.healthKit));
      expect(find.byIcon(CupertinoIcons.heart), findsOneWidget);
      expect(find.text(AppStrings.nowCardProofHealthKit), findsOneWidget);
    });

    testWidgets('calendarEvent shows calendar icon', (tester) async {
      await tester.pumpWidget(buildIndicator(ProofMode.calendarEvent));
      expect(find.byIcon(CupertinoIcons.calendar), findsOneWidget);
      expect(find.text(AppStrings.nowCardProofCalendarEvent), findsOneWidget);
    });
  });

  group('CommitmentRow', () {
    testWidgets('renders formatted amount display', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
          home: const Scaffold(
            body: CommitmentRow(
              stakeAmountCents: 2500,
              textColor: Color(0xFF000000),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('\$25'), findsOneWidget);
      expect(find.text(AppStrings.nowCardStakeLabel), findsOneWidget);
    });

    testWidgets('renders nothing when null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
          home: const Scaffold(
            body: CommitmentRow(
              stakeAmountCents: null,
              textColor: Color(0xFF000000),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text(AppStrings.nowCardStakeLabel), findsNothing);
    });

    test('formatAmount handles cents correctly', () {
      expect(CommitmentRow.formatAmount(2500), '\$25');
      expect(CommitmentRow.formatAmount(1050), '\$10.50');
      expect(CommitmentRow.formatAmount(100), '\$1');
      expect(CommitmentRow.formatAmount(99), '\$0.99');
    });
  });
}

// ── Fake notifier for testing ───────────────────────────────────────────────

class _FakeNowNotifier extends Now {
  final NowTask? _task;
  final bool loading;

  _FakeNowNotifier(this._task, {this.loading = false});

  @override
  Future<NowTask?> build() async {
    if (loading) {
      // Simulate a long loading state
      await Future.delayed(const Duration(seconds: 10));
    }
    return _task;
  }
}
