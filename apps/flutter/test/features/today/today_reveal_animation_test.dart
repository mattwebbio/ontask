import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ontask/core/motion/motion_tokens.dart';
import 'package:ontask/core/theme/app_theme.dart';

// We test the _RevealAnimation indirectly via the MotionTokens constants
// and a custom widget that mirrors the same animation pattern.

/// A minimal widget that mirrors the _RevealAnimation behaviour from today_screen.dart,
/// used to test the Reduce Motion pattern independently of the full Today screen.
class _RevealAnimationTestWidget extends StatefulWidget {
  final bool startAnimation;
  const _RevealAnimationTestWidget({required this.startAnimation});

  @override
  State<_RevealAnimationTestWidget> createState() =>
      _RevealAnimationTestWidgetState();
}

class _RevealAnimationTestWidgetState extends State<_RevealAnimationTestWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  bool _animationStarted = false;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      duration: Duration(milliseconds: MotionTokens.revealDurationMs),
      vsync: this,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_animationStarted && widget.startAnimation) {
      _animationStarted = true;
      final disableAnimations = MediaQuery.of(context).disableAnimations;
      if (disableAnimations) {
        controller.value = 1.0; // instant — no animation
      } else {
        controller.forward();
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, _) => Opacity(
        opacity: controller.value,
        child: const SizedBox(width: 100, height: 44, key: Key('row')),
      ),
    );
  }
}

Widget _buildApp({bool disableAnimations = false, bool startAnimation = true}) {
  return MaterialApp(
    theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Scaffold(
        body: _RevealAnimationTestWidget(startAnimation: startAnimation),
      ),
    ),
  );
}

void main() {
  group('Today reveal animation (The reveal — UX-DR20)', () {
    testWidgets(
        'with disableAnimations: true, row renders at full opacity immediately',
        (tester) async {
      await tester.pumpWidget(
        _buildApp(disableAnimations: true, startAnimation: true),
      );
      // No pump needed — should be at full opacity immediately (value = 1.0)
      final opacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacity.opacity, equals(1.0));
    });

    testWidgets(
        'with disableAnimations: false, AnimationController starts at 0 and forward is called',
        (tester) async {
      await tester.pumpWidget(
        _buildApp(disableAnimations: false, startAnimation: true),
      );

      // On first pump (before animation ticks), opacity starts near 0
      final opacityBefore = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacityBefore.opacity, lessThan(1.0));

      // Pump through the full animation duration
      await tester.pump(
        Duration(milliseconds: MotionTokens.revealDurationMs + 50),
      );

      final opacityAfter = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacityAfter.opacity, equals(1.0));
    });

    testWidgets('row renders at all times (no invisible initial state when not animating)',
        (tester) async {
      await tester.pumpWidget(
        _buildApp(disableAnimations: true, startAnimation: false),
      );
      // Widget is present regardless
      expect(find.byKey(const Key('row')), findsOneWidget);
    });
  });

  group('MotionTokens constants have expected values', () {
    test('revealStaggerMs equals 50', () {
      expect(MotionTokens.revealStaggerMs, 50);
    });

    test('revealDurationMs equals 300', () {
      expect(MotionTokens.revealDurationMs, 300);
    });

    test('planShiftsDurationMs equals 400', () {
      expect(MotionTokens.planShiftsDurationMs, 400);
    });
  });
}
