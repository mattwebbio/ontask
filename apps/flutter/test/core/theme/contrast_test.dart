import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontask/core/theme/app_theme.dart';

void main() {
  const serifFamily = 'PlayfairDisplay';

  /// WCAG 2.1 relative luminance of a sRGB colour.
  double relativeLuminance(Color c) {
    double linearize(double v) =>
        v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4).toDouble();

    final r = linearize(c.red / 255);
    final g = linearize(c.green / 255);
    final b = linearize(c.blue / 255);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// WCAG contrast ratio between two colours.
  double contrastRatio(Color fg, Color bg) {
    final l1 = relativeLuminance(fg);
    final l2 = relativeLuminance(bg);
    return (max(l1, l2) + 0.05) / (min(l1, l2) + 0.05);
  }

  group('WCAG 2.1 AA — body text (17pt) vs surface: ≥4.5:1', () {
    for (final variant in ThemeVariant.values) {
      test('light(${variant.name}): body text ≥ 4.5:1', () {
        final theme = AppTheme.light(variant, serifFamily);
        final fg = theme.colorScheme.onSurface;
        final bg = theme.colorScheme.surface;
        final ratio = contrastRatio(fg, bg);
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason:
              '${variant.name} light: body text contrast $ratio is below WCAG AA 4.5:1 '
              '(fg: #${fg.value.toRadixString(16)}, bg: #${bg.value.toRadixString(16)})',
        );
      });

      test('dark(${variant.name}): body text ≥ 4.5:1', () {
        final theme = AppTheme.dark(variant, serifFamily);
        final fg = theme.colorScheme.onSurface;
        final bg = theme.colorScheme.surface;
        final ratio = contrastRatio(fg, bg);
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason:
              '${variant.name} dark: body text contrast $ratio is below WCAG AA 4.5:1 '
              '(fg: #${fg.value.toRadixString(16)}, bg: #${bg.value.toRadixString(16)})',
        );
      });
    }
  });

  group('WCAG 2.1 AA — large text (22pt+) vs surface: ≥3:1', () {
    for (final variant in ThemeVariant.values) {
      test('light(${variant.name}): large text ≥ 3:1', () {
        final theme = AppTheme.light(variant, serifFamily);
        final fg = theme.colorScheme.onSurface;
        final bg = theme.colorScheme.surface;
        final ratio = contrastRatio(fg, bg);
        expect(
          ratio,
          greaterThanOrEqualTo(3.0),
          reason:
              '${variant.name} light: large text contrast $ratio is below WCAG AA 3:1 '
              '(fg: #${fg.value.toRadixString(16)}, bg: #${bg.value.toRadixString(16)})',
        );
      });

      test('dark(${variant.name}): large text ≥ 3:1', () {
        final theme = AppTheme.dark(variant, serifFamily);
        final fg = theme.colorScheme.onSurface;
        final bg = theme.colorScheme.surface;
        final ratio = contrastRatio(fg, bg);
        expect(
          ratio,
          greaterThanOrEqualTo(3.0),
          reason:
              '${variant.name} dark: large text contrast $ratio is below WCAG AA 3:1 '
              '(fg: #${fg.value.toRadixString(16)}, bg: #${bg.value.toRadixString(16)})',
        );
      });
    }
  });

  // Spot-check actual contrast values for documentation purposes
  group('WCAG — spot-check Clay theme tokens', () {
    test('Clay light: primary text on surface primary has sufficient contrast', () {
      final theme = AppTheme.light(ThemeVariant.clay, serifFamily);
      // Clay light: text #1C1410 on surface #FDF6EE
      final ratio = contrastRatio(
        theme.colorScheme.onSurface,
        theme.colorScheme.surface,
      );
      // Expect at least 10:1 for this high-contrast pair
      expect(ratio, greaterThanOrEqualTo(10.0),
          reason: 'Clay light text on cream surface should be very high contrast');
    });

    test('Clay dark: primary text on surface primary has sufficient contrast', () {
      final theme = AppTheme.dark(ThemeVariant.clay, serifFamily);
      final ratio = contrastRatio(
        theme.colorScheme.onSurface,
        theme.colorScheme.surface,
      );
      expect(ratio, greaterThanOrEqualTo(8.0),
          reason: 'Clay dark cream text on dark surface should be high contrast');
    });
  });
}
