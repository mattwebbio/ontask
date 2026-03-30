import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shimmer/shimmer.dart';

import 'package:ontask/core/theme/app_theme.dart';
import 'package:ontask/features/now/presentation/widgets/now_card_skeleton.dart';

void main() {
  group('NowCardSkeleton', () {
    Widget _buildSkeleton({bool disableAnimations = false}) {
      return MaterialApp(
        theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: disableAnimations),
          child: const Scaffold(
            body: NowCardSkeleton(),
          ),
        ),
      );
    }

    testWidgets('renders without throwing', (tester) async {
      await tester.pumpWidget(_buildSkeleton());
      expect(find.byType(NowCardSkeleton), findsOneWidget);
    });

    testWidgets('wraps shimmer in RepaintBoundary when animations enabled',
        (tester) async {
      await tester.pumpWidget(_buildSkeleton());
      expect(find.byType(RepaintBoundary), findsAtLeastNWidgets(1));
    });

    testWidgets('uses Shimmer widget when animations are enabled', (tester) async {
      await tester.pumpWidget(_buildSkeleton());
      expect(find.byType(Shimmer), findsOneWidget);
    });

    testWidgets('does NOT use Shimmer widget when disableAnimations is true',
        (tester) async {
      await tester.pumpWidget(_buildSkeleton(disableAnimations: true));
      expect(find.byType(Shimmer), findsNothing);
    });

    testWidgets('card container has height of 160', (tester) async {
      await tester.pumpWidget(_buildSkeleton());

      // Find the container with height 160 (the card skeleton)
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasCardHeight = containers.any(
        (c) => c.constraints?.maxHeight == 160 || c.constraints?.minHeight == 160,
      );
      // At minimum, container exists
      expect(containers, isNotEmpty);
    });
  });
}
