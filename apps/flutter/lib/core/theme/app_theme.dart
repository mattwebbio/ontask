import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// Named theme variants available in the app.
enum ThemeVariant { clay, slate, dusk, monochrome }

/// Builds [ThemeData] instances for all [ThemeVariant] × light/dark combos.
///
/// Usage:
/// ```dart
/// AppTheme.light(ThemeVariant.clay, fontConfig.serifFamily)
/// AppTheme.dark(ThemeVariant.clay, fontConfig.serifFamily)
/// ```
///
/// The [serifFontFamily] string is resolved at startup via [FontConfig] and
/// passed in here — do NOT look it up inside this class.
class AppTheme {
  AppTheme._();

  /// Returns the light [ThemeData] for [variant].
  static ThemeData light(ThemeVariant variant, String serifFontFamily) {
    return _buildTheme(
      variant: variant,
      brightness: Brightness.light,
      serifFontFamily: serifFontFamily,
    );
  }

  /// Returns the dark [ThemeData] for [variant].
  static ThemeData dark(ThemeVariant variant, String serifFontFamily) {
    return _buildTheme(
      variant: variant,
      brightness: Brightness.dark,
      serifFontFamily: serifFontFamily,
    );
  }

  static ThemeData _buildTheme({
    required ThemeVariant variant,
    required Brightness brightness,
    required String serifFontFamily,
  }) {
    final colors = _colorsFor(variant, brightness);
    final textTheme = _buildTextTheme(serifFontFamily);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: colors.accentPrimary,
        onPrimary: colors.surfacePrimary,
        secondary: colors.accentCompletion,
        onSecondary: colors.surfacePrimary,
        error: AppColors.scheduleCritical,
        onError: colors.surfacePrimary,
        surface: colors.surfacePrimary,
        onSurface: colors.textPrimary,
        surfaceContainerHighest: colors.surfaceSecondary,
        outline: colors.textSecondary,
        tertiary: colors.accentCommitment,
        onTertiary: colors.surfacePrimary,
      ),
      scaffoldBackgroundColor: colors.surfacePrimary,
      textTheme: textTheme,
      extensions: [
        _OnTaskColors(
          surfacePrimary: colors.surfacePrimary,
          surfaceSecondary: colors.surfaceSecondary,
          accentPrimary: colors.accentPrimary,
          accentCommitment: colors.accentCommitment,
          accentCompletion: colors.accentCompletion,
          textPrimary: colors.textPrimary,
          textSecondary: colors.textSecondary,
          stakeZoneLow: AppColors.stakeZoneLow,
          stakeZoneMid: AppColors.stakeZoneMid,
          stakeZoneHigh: AppColors.stakeZoneHigh,
          scheduleHealthy: AppColors.scheduleHealthy,
          scheduleAtRisk: AppColors.scheduleAtRisk,
          scheduleCritical: AppColors.scheduleCritical,
        ),
      ],
    );
  }

  static _ThemeColors _colorsFor(ThemeVariant variant, Brightness brightness) {
    switch (variant) {
      case ThemeVariant.clay:
        return brightness == Brightness.light
            ? const _ThemeColors(
                surfacePrimary: AppColors.clayLightSurfacePrimary,
                surfaceSecondary: AppColors.clayLightSurfaceSecondary,
                accentPrimary: AppColors.clayLightAccentPrimary,
                accentCommitment: AppColors.clayLightAccentCommitment,
                accentCompletion: AppColors.clayLightAccentCompletion,
                textPrimary: AppColors.clayLightTextPrimary,
                textSecondary: AppColors.clayLightTextSecondary,
              )
            : const _ThemeColors(
                surfacePrimary: AppColors.clayDarkSurfacePrimary,
                surfaceSecondary: AppColors.clayDarkSurfaceSecondary,
                accentPrimary: AppColors.clayDarkAccentPrimary,
                accentCommitment: AppColors.clayDarkAccentCommitment,
                accentCompletion: AppColors.clayDarkAccentCompletion,
                textPrimary: AppColors.clayDarkTextPrimary,
                textSecondary: AppColors.clayDarkTextSecondary,
              );

      case ThemeVariant.slate:
        return brightness == Brightness.light
            ? const _ThemeColors(
                surfacePrimary: AppColors.slateLightSurfacePrimary,
                surfaceSecondary: AppColors.slateLightSurfaceSecondary,
                accentPrimary: AppColors.slateLightAccentPrimary,
                accentCommitment: AppColors.slateLightAccentCommitment,
                accentCompletion: AppColors.slateLightAccentCompletion,
                textPrimary: AppColors.slateLightTextPrimary,
                textSecondary: AppColors.slateLightTextSecondary,
              )
            : const _ThemeColors(
                surfacePrimary: AppColors.slateDarkSurfacePrimary,
                surfaceSecondary: AppColors.slateDarkSurfaceSecondary,
                accentPrimary: AppColors.slateDarkAccentPrimary,
                accentCommitment: AppColors.slateDarkAccentCommitment,
                accentCompletion: AppColors.slateDarkAccentCompletion,
                textPrimary: AppColors.slateDarkTextPrimary,
                textSecondary: AppColors.slateDarkTextSecondary,
              );

      case ThemeVariant.dusk:
        return brightness == Brightness.light
            ? const _ThemeColors(
                surfacePrimary: AppColors.duskLightSurfacePrimary,
                surfaceSecondary: AppColors.duskLightSurfaceSecondary,
                accentPrimary: AppColors.duskLightAccentPrimary,
                accentCommitment: AppColors.duskLightAccentCommitment,
                accentCompletion: AppColors.duskLightAccentCompletion,
                textPrimary: AppColors.duskLightTextPrimary,
                textSecondary: AppColors.duskLightTextSecondary,
              )
            : const _ThemeColors(
                surfacePrimary: AppColors.duskDarkSurfacePrimary,
                surfaceSecondary: AppColors.duskDarkSurfaceSecondary,
                accentPrimary: AppColors.duskDarkAccentPrimary,
                accentCommitment: AppColors.duskDarkAccentCommitment,
                accentCompletion: AppColors.duskDarkAccentCompletion,
                textPrimary: AppColors.duskDarkTextPrimary,
                textSecondary: AppColors.duskDarkTextSecondary,
              );

      case ThemeVariant.monochrome:
        return brightness == Brightness.light
            ? const _ThemeColors(
                surfacePrimary: AppColors.monochromeLightSurfacePrimary,
                surfaceSecondary: AppColors.monochromeLightSurfaceSecondary,
                accentPrimary: AppColors.monochromeLightAccentPrimary,
                accentCommitment: AppColors.monochromeLightAccentCommitment,
                accentCompletion: AppColors.monochromeLightAccentCompletion,
                textPrimary: AppColors.monochromeLightTextPrimary,
                textSecondary: AppColors.monochromeLightTextSecondary,
              )
            : const _ThemeColors(
                surfacePrimary: AppColors.monochromeDarkSurfacePrimary,
                surfaceSecondary: AppColors.monochromeDarkSurfaceSecondary,
                accentPrimary: AppColors.monochromeDarkAccentPrimary,
                accentCommitment: AppColors.monochromeDarkAccentCommitment,
                accentCompletion: AppColors.monochromeDarkAccentCompletion,
                textPrimary: AppColors.monochromeDarkTextPrimary,
                textSecondary: AppColors.monochromeDarkTextSecondary,
              );
    }
  }

  static TextTheme _buildTextTheme(String serifFontFamily) {
    // System (sans-serif) styles — fontFamily null = system default (SF Pro on iOS)
    // Serif styles — fontFamily = resolved serifFontFamily at runtime
    return TextTheme(
      displayLarge: AppTextStyles.impactMilestone.copyWith(
        fontFamily: serifFontFamily,
      ),
      displayMedium: AppTextStyles.heroTask,
      displaySmall: AppTextStyles.sectionHeading,
      headlineMedium: AppTextStyles.sectionHeading,
      headlineSmall: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
      titleLarge: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
      titleMedium: AppTextStyles.secondary.copyWith(fontWeight: FontWeight.w600),
      titleSmall: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: AppTextStyles.body,
      bodyMedium: AppTextStyles.secondary,
      bodySmall: AppTextStyles.caption,
      labelLarge: AppTextStyles.secondary.copyWith(fontWeight: FontWeight.w600),
      labelMedium: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
      labelSmall: AppTextStyles.caption,
    );
  }
}

// ─── Private colour bundle ───────────────────────────────────────────────────

class _ThemeColors {
  final Color surfacePrimary;
  final Color surfaceSecondary;
  final Color accentPrimary;
  final Color accentCommitment;
  final Color accentCompletion;
  final Color textPrimary;
  final Color textSecondary;

  const _ThemeColors({
    required this.surfacePrimary,
    required this.surfaceSecondary,
    required this.accentPrimary,
    required this.accentCommitment,
    required this.accentCompletion,
    required this.textPrimary,
    required this.textSecondary,
  });
}

// ─── ThemeExtension for OnTask-specific tokens ───────────────────────────────

/// A [ThemeExtension] that exposes OnTask design tokens beyond standard
/// Material [ColorScheme] — available via [Theme.of(context).extension<_OnTaskColors>()].
///
/// Not exported publicly; access through [Theme.of(context).colorScheme] for
/// standard tokens. This extension carries the full OnTask palette.
@immutable
class _OnTaskColors extends ThemeExtension<_OnTaskColors> {
  final Color surfacePrimary;
  final Color surfaceSecondary;
  final Color accentPrimary;
  final Color accentCommitment;
  final Color accentCompletion;
  final Color textPrimary;
  final Color textSecondary;
  final Color stakeZoneLow;
  final Color stakeZoneMid;
  final Color stakeZoneHigh;
  final Color scheduleHealthy;
  final Color scheduleAtRisk;
  final Color scheduleCritical;

  const _OnTaskColors({
    required this.surfacePrimary,
    required this.surfaceSecondary,
    required this.accentPrimary,
    required this.accentCommitment,
    required this.accentCompletion,
    required this.textPrimary,
    required this.textSecondary,
    required this.stakeZoneLow,
    required this.stakeZoneMid,
    required this.stakeZoneHigh,
    required this.scheduleHealthy,
    required this.scheduleAtRisk,
    required this.scheduleCritical,
  });

  @override
  _OnTaskColors copyWith({
    Color? surfacePrimary,
    Color? surfaceSecondary,
    Color? accentPrimary,
    Color? accentCommitment,
    Color? accentCompletion,
    Color? textPrimary,
    Color? textSecondary,
    Color? stakeZoneLow,
    Color? stakeZoneMid,
    Color? stakeZoneHigh,
    Color? scheduleHealthy,
    Color? scheduleAtRisk,
    Color? scheduleCritical,
  }) {
    return _OnTaskColors(
      surfacePrimary: surfacePrimary ?? this.surfacePrimary,
      surfaceSecondary: surfaceSecondary ?? this.surfaceSecondary,
      accentPrimary: accentPrimary ?? this.accentPrimary,
      accentCommitment: accentCommitment ?? this.accentCommitment,
      accentCompletion: accentCompletion ?? this.accentCompletion,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      stakeZoneLow: stakeZoneLow ?? this.stakeZoneLow,
      stakeZoneMid: stakeZoneMid ?? this.stakeZoneMid,
      stakeZoneHigh: stakeZoneHigh ?? this.stakeZoneHigh,
      scheduleHealthy: scheduleHealthy ?? this.scheduleHealthy,
      scheduleAtRisk: scheduleAtRisk ?? this.scheduleAtRisk,
      scheduleCritical: scheduleCritical ?? this.scheduleCritical,
    );
  }

  @override
  _OnTaskColors lerp(_OnTaskColors? other, double t) {
    if (other == null) return this;
    return _OnTaskColors(
      surfacePrimary: Color.lerp(surfacePrimary, other.surfacePrimary, t)!,
      surfaceSecondary:
          Color.lerp(surfaceSecondary, other.surfaceSecondary, t)!,
      accentPrimary: Color.lerp(accentPrimary, other.accentPrimary, t)!,
      accentCommitment:
          Color.lerp(accentCommitment, other.accentCommitment, t)!,
      accentCompletion:
          Color.lerp(accentCompletion, other.accentCompletion, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      stakeZoneLow: Color.lerp(stakeZoneLow, other.stakeZoneLow, t)!,
      stakeZoneMid: Color.lerp(stakeZoneMid, other.stakeZoneMid, t)!,
      stakeZoneHigh: Color.lerp(stakeZoneHigh, other.stakeZoneHigh, t)!,
      scheduleHealthy: Color.lerp(scheduleHealthy, other.scheduleHealthy, t)!,
      scheduleAtRisk: Color.lerp(scheduleAtRisk, other.scheduleAtRisk, t)!,
      scheduleCritical:
          Color.lerp(scheduleCritical, other.scheduleCritical, t)!,
    );
  }
}
