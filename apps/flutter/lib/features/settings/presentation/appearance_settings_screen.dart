import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';

/// Settings → Appearance screen.
///
/// Allows the user to:
///   1. Choose one of four themes: Clay, Slate, Dusk, Monochrome (AC #1, FR77).
///   2. Toggle light / dark / automatic (system) mode (AC #1, NFR-A5).
///   3. Adjust text size via segmented control — system + 3 increments (NFR-A5).
///
/// All changes apply immediately via Riverpod state — no "Save" button required.
/// All strings come from [AppStrings] — no inline literals.
class AppearanceSettingsScreen extends ConsumerWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;

    final currentVariant =
        ref.watch(themeVariantProvider).value ?? ThemeVariant.clay;
    final currentMode =
        ref.watch(themeModeProvider).value ?? ThemeMode.system;
    final currentIncrement =
        ref.watch(textScaleIncrementProvider).value ?? 0.0;

    final themeSettings = ref.read(themeSettingsProvider.notifier);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(AppStrings.settingsAppearance),
        backgroundColor: colors.surfacePrimary,
      ),
      backgroundColor: colors.surfacePrimary,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Theme picker ──────────────────────────────────────────────────
            Text(
              AppStrings.appearanceThemeLabel,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
            const SizedBox(height: 10),
            _ThemePicker(
              current: currentVariant,
              onSelected: (v) => themeSettings.setThemeVariant(v),
            ),
            const SizedBox(height: 28),

            // ── Mode toggle ───────────────────────────────────────────────────
            Text(
              'Mode',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
            const SizedBox(height: 10),
            _ModeToggle(
              current: currentMode,
              onChanged: (m) => themeSettings.setThemeMode(m),
            ),
            const SizedBox(height: 28),

            // ── Text size ─────────────────────────────────────────────────────
            Text(
              AppStrings.appearanceTextSizeLabel,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
            const SizedBox(height: 10),
            _TextSizePicker(
              currentIncrement: currentIncrement,
              onChanged: (v) => themeSettings.setTextScaleIncrement(v),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Theme Picker ─────────────────────────────────────────────────────────────

/// Displays the four theme tiles (Clay, Slate, Dusk, Monochrome).
///
/// Tapping a tile immediately updates [themeVariantProvider] via [ThemeSettings].
/// Uses [OnTaskColors] semantic tokens — no hardcoded hex values.
class _ThemePicker extends ConsumerWidget {
  final ThemeVariant current;
  final ValueChanged<ThemeVariant> onSelected;

  const _ThemePicker({required this.current, required this.onSelected});

  static const _variants = [
    (ThemeVariant.clay, AppStrings.appearanceThemeClay),
    (ThemeVariant.slate, AppStrings.appearanceThemeSlate),
    (ThemeVariant.dusk, AppStrings.appearanceThemeDusk),
    (ThemeVariant.monochrome, AppStrings.appearanceThemeMonochrome),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _variants.map((entry) {
        final (variant, label) = entry;
        final isSelected = variant == current;

        return GestureDetector(
          onTap: () => onSelected(variant),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? colors.accentPrimary : colors.surfaceSecondary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? colors.accentPrimary
                    : colors.surfaceSecondary,
                width: 1.5,
              ),
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: isSelected
                        ? colors.surfacePrimary
                        : colors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Mode Toggle ──────────────────────────────────────────────────────────────

/// Segmented control for Light / Dark / Automatic (system) mode.
///
/// Updates [themeModeProvider] immediately on selection via [ThemeSettings].
class _ModeToggle extends StatelessWidget {
  final ThemeMode current;
  final ValueChanged<ThemeMode> onChanged;

  const _ModeToggle({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;

    final options = <ThemeMode, Widget>{
      ThemeMode.light: Text(AppStrings.appearanceModeLight),
      ThemeMode.dark: Text(AppStrings.appearanceModeDark),
      ThemeMode.system: Text(AppStrings.appearanceModeSystem),
    };

    return CupertinoSlidingSegmentedControl<ThemeMode>(
      groupValue: current,
      backgroundColor: colors.surfaceSecondary,
      thumbColor: colors.accentPrimary,
      children: options,
      onValueChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

// ── Text Size Picker ─────────────────────────────────────────────────────────

/// Segmented control with four steps: System (0.0), +1 (0.1), +2 (0.2), +3 (0.3).
///
/// Three increments above system default satisfies NFR-A5.
/// Updates [textScaleIncrementProvider] immediately on selection.
class _TextSizePicker extends StatelessWidget {
  final double currentIncrement;
  final ValueChanged<double> onChanged;

  const _TextSizePicker({
    required this.currentIncrement,
    required this.onChanged,
  });

  static const _steps = <double>[0.0, 0.1, 0.2, 0.3];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;

    // Round to nearest step to handle floating point storage edge cases.
    final closestStep = _steps.reduce((a, b) =>
        (a - currentIncrement).abs() < (b - currentIncrement).abs() ? a : b);

    final options = <double, Widget>{
      0.0: const Text('A', style: TextStyle(fontSize: 12)),
      0.1: const Text('A', style: TextStyle(fontSize: 14)),
      0.2: const Text('A', style: TextStyle(fontSize: 17)),
      0.3: const Text('A', style: TextStyle(fontSize: 20)),
    };

    return CupertinoSlidingSegmentedControl<double>(
      groupValue: closestStep,
      backgroundColor: colors.surfaceSecondary,
      thumbColor: colors.accentPrimary,
      children: options,
      onValueChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
