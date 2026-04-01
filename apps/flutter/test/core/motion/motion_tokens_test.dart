import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontask/core/motion/motion_tokens.dart';

void main() {
  group('MotionTokens constants', () {
    test('revealStaggerMs is 50', () {
      expect(MotionTokens.revealStaggerMs, equals(50));
    });

    test('revealDurationMs is 300', () {
      expect(MotionTokens.revealDurationMs, equals(300));
    });

    test('planShiftsDurationMs is 400', () {
      expect(MotionTokens.planShiftsDurationMs, equals(400));
    });
  });

  group('isReducedMotion', () {
    testWidgets('returns false when disableAnimations is false', (tester) async {
      late bool result;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: false),
          child: Builder(
            builder: (context) {
              result = isReducedMotion(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(result, isFalse);
    });

    testWidgets('returns true when disableAnimations is true', (tester) async {
      late bool result;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (context) {
              result = isReducedMotion(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(result, isTrue);
    });
  });
}
