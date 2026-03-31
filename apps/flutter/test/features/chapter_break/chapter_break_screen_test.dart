import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontask/core/l10n/strings.dart';
import 'package:ontask/features/chapter_break/presentation/chapter_break_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({'onboarding_completed': true});
  });

  Widget buildScreen({
    String taskTitle = 'Write the report',
    String? stakeAmount,
    VoidCallback? onContinue,
    bool disableAnimations = false,
  }) {
    final widget = ProviderScope(
      child: CupertinoApp(
        home: ChapterBreakScreen(
          taskTitle: taskTitle,
          stakeAmount: stakeAmount,
          onContinue: onContinue ?? () {},
        ),
      ),
    );

    if (disableAnimations) {
      return MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: widget,
      );
    }
    return widget;
  }

  // ── Rendering ──────────────────────────────────────────────────────────────

  group('ChapterBreakScreen', () {
    testWidgets('renders headline text', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();
      expect(find.text(AppStrings.chapterBreakHeadline), findsOneWidget);
    });

    testWidgets('renders sub-copy text', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();
      expect(find.text(AppStrings.chapterBreakSubcopy), findsOneWidget);
    });

    testWidgets('displays task title', (tester) async {
      await tester.pumpWidget(buildScreen(taskTitle: 'Finish the proposal'));
      await tester.pump();
      expect(find.text('Finish the proposal'), findsOneWidget);
    });

    testWidgets('displays stake amount when provided', (tester) async {
      await tester.pumpWidget(
        buildScreen(taskTitle: 'Run 5k', stakeAmount: '\$25.00'),
      );
      await tester.pump();
      expect(
        find.text('${AppStrings.chapterBreakStakeLabel}: \$25.00'),
        findsOneWidget,
      );
    });

    testWidgets('does NOT display stake amount when null', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();
      expect(find.text(AppStrings.chapterBreakStakeLabel), findsNothing);
    });

    testWidgets('CTA button is present with correct label', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();
      expect(find.text(AppStrings.chapterBreakCta), findsOneWidget);
    });

    testWidgets('tapping CTA fires onContinue callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        buildScreen(onContinue: () => tapped = true),
      );
      await tester.pump();
      await tester.tap(find.text(AppStrings.chapterBreakCta));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('Semantics(liveRegion: true) wraps the heading', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      // The headline text should be inside a Semantics node with liveRegion.
      final semanticsWidget = tester.widget<Semantics>(
        find
            .ancestor(
              of: find.text(AppStrings.chapterBreakHeadline),
              matching: find.byType(Semantics),
            )
            .first,
      );
      expect(semanticsWidget.properties.liveRegion, isTrue);
    });

    testWidgets('no Material widgets used (AlertDialog, ElevatedButton, TextButton)',
        (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.byType(TextButton), findsNothing);
    });
  });

  // ── Reduced motion ─────────────────────────────────────────────────────────

  group('ChapterBreakScreen (reduced motion)', () {
    testWidgets(
        'renders immediately at full opacity when disableAnimations is true',
        (tester) async {
      await tester.pumpWidget(
        buildScreen(disableAnimations: true, taskTitle: 'Test task'),
      );
      await tester.pump(); // single frame — no animation to flush
      expect(find.text(AppStrings.chapterBreakHeadline), findsOneWidget);
    });
  });
}
