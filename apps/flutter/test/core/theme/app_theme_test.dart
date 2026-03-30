import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontask/core/theme/app_text_styles.dart';
import 'package:ontask/core/theme/app_theme.dart';

void main() {
  const serifFamily = 'PlayfairDisplay';

  group('AppTheme — 8 ThemeData instances exist', () {
    for (final variant in ThemeVariant.values) {
      test('light(${variant.name}) returns non-null ThemeData', () {
        final theme = AppTheme.light(variant, serifFamily);
        expect(theme, isNotNull);
        expect(theme.colorScheme.primary, isNotNull);
      });

      test('dark(${variant.name}) returns non-null ThemeData', () {
        final theme = AppTheme.dark(variant, serifFamily);
        expect(theme, isNotNull);
        expect(theme.colorScheme.primary, isNotNull);
      });
    }
  });

  group('AppTheme — all 8 variants have non-null color tokens', () {
    for (final variant in ThemeVariant.values) {
      for (final brightness in Brightness.values) {
        final label = '${variant.name} ${brightness.name}';
        test('$label colorScheme tokens are non-null', () {
          final theme = brightness == Brightness.light
              ? AppTheme.light(variant, serifFamily)
              : AppTheme.dark(variant, serifFamily);

          expect(theme.colorScheme.primary, isNotNull);
          expect(theme.colorScheme.surface, isNotNull);
          expect(theme.colorScheme.onSurface, isNotNull);
        });
      }
    }
  });

  group('AppTextStyles — token integrity checks', () {
    test('body fontSize equals 17', () {
      expect(AppTextStyles.body.fontSize, equals(17));
    });

    test('heroTask fontSize equals 28', () {
      expect(AppTextStyles.heroTask.fontSize, equals(28));
    });

    test('sectionHeading fontSize equals 22', () {
      expect(AppTextStyles.sectionHeading.fontSize, equals(22));
    });

    test('secondary fontSize equals 15', () {
      expect(AppTextStyles.secondary.fontSize, equals(15));
    });

    test('caption fontSize equals 13', () {
      expect(AppTextStyles.caption.fontSize, equals(13));
    });

    test('impactMilestone fontSize equals 34', () {
      expect(AppTextStyles.impactMilestone.fontSize, equals(34));
    });
  });

  group('AppTheme — textTheme uses token sizes (no rogue hardcoded fontSize)', () {
    /// Ensures that every TextStyle in the ThemeData.textTheme uses a fontSize
    /// that corresponds to one of the AppTextStyles token sizes.
    /// This is the enforcement for NFR-A3 (no hardcoded font sizes in widgets).
    final tokenSizes = {13.0, 15.0, 17.0, 20.0, 22.0, 28.0, 34.0};

    for (final variant in ThemeVariant.values) {
      test('light(${variant.name}) textTheme fontSizes are from token set', () {
        final theme = AppTheme.light(variant, serifFamily);
        _assertTextThemeUsesTokens(theme.textTheme, tokenSizes);
      });

      test('dark(${variant.name}) textTheme fontSizes are from token set', () {
        final theme = AppTheme.dark(variant, serifFamily);
        _assertTextThemeUsesTokens(theme.textTheme, tokenSizes);
      });
    }
  });
}

void _assertTextThemeUsesTokens(TextTheme textTheme, Set<double> tokenSizes) {
  final styles = [
    textTheme.displayLarge,
    textTheme.displayMedium,
    textTheme.displaySmall,
    textTheme.headlineMedium,
    textTheme.headlineSmall,
    textTheme.titleLarge,
    textTheme.titleMedium,
    textTheme.titleSmall,
    textTheme.bodyLarge,
    textTheme.bodyMedium,
    textTheme.bodySmall,
    textTheme.labelLarge,
    textTheme.labelMedium,
    textTheme.labelSmall,
  ];

  for (final style in styles) {
    if (style == null) continue;
    final fontSize = style.fontSize;
    if (fontSize != null) {
      expect(
        tokenSizes.contains(fontSize),
        isTrue,
        reason:
            'TextStyle has hardcoded fontSize $fontSize not in token set $tokenSizes. '
            'All font sizes must come from AppTextStyles tokens.',
      );
    }
  }
}
