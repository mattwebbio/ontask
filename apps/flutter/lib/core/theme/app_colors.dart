import 'package:flutter/material.dart';

/// All raw colour constants for all 4 themes × 2 variants.
///
/// Widgets NEVER reference these constants directly — all semantic usage
/// goes through [AppTheme] / [Theme.of(context).colorScheme].
class AppColors {
  AppColors._();

  // ─────────────────────────────────────────────────────────
  // Clay — Terracotta & Cream
  // ─────────────────────────────────────────────────────────

  // Clay Light
  static const Color clayLightSurfacePrimary = Color(0xFFFDF6EE);
  static const Color clayLightSurfaceSecondary = Color(0xFFF5EDE2);
  static const Color clayLightAccentPrimary = Color(0xFFC4623A); // terracotta
  static const Color clayLightAccentCommitment = Color(0xFF231A14);
  static const Color clayLightAccentCompletion = Color(0xFFC98A2E);
  static const Color clayLightTextPrimary = Color(0xFF1C1410);
  static const Color clayLightTextSecondary = Color(0xFF6B5242);

  // Clay Dark
  static const Color clayDarkSurfacePrimary = Color(0xFF1C1410);
  static const Color clayDarkSurfaceSecondary = Color(0xFF261B14);
  static const Color clayDarkAccentPrimary = Color(0xFFD4724A);
  static const Color clayDarkAccentCommitment = Color(0xFFF5EDE4);
  static const Color clayDarkAccentCompletion = Color(0xFFD49A3A);
  static const Color clayDarkTextPrimary = Color(0xFFF5EDE4);
  static const Color clayDarkTextSecondary = Color(0xFFB89880);

  // ─────────────────────────────────────────────────────────
  // Slate — Charcoal & Gold (UX spec: "Forge")
  // ─────────────────────────────────────────────────────────

  // Slate Light
  static const Color slateLightSurfacePrimary = Color(0xFFF5F5F3);
  static const Color slateLightSurfaceSecondary = Color(0xFFEAEAE8);
  static const Color slateLightAccentPrimary = Color(0xFFC4922A); // warm gold
  static const Color slateLightAccentCommitment = Color(0xFF0D0D0D);
  static const Color slateLightAccentCompletion = Color(0xFFC4922A);
  static const Color slateLightTextPrimary = Color(0xFF1A1A1A);
  static const Color slateLightTextSecondary = Color(0xFF5C5C5C);

  // Slate Dark
  static const Color slateDarkSurfacePrimary = Color(0xFF1A1A1A);
  static const Color slateDarkSurfaceSecondary = Color(0xFF262626);
  static const Color slateDarkAccentPrimary = Color(0xFFD4A83A);
  static const Color slateDarkAccentCommitment = Color(0xFFF0EFED);
  static const Color slateDarkAccentCompletion = Color(0xFFD4A83A);
  static const Color slateDarkTextPrimary = Color(0xFFF0EFED);
  static const Color slateDarkTextSecondary = Color(0xFF9E9E9E);

  // ─────────────────────────────────────────────────────────
  // Dusk — Deep Indigo & Warm Off-White
  // ─────────────────────────────────────────────────────────

  // Dusk Light
  static const Color duskLightSurfacePrimary = Color(0xFFF8F5F2);
  static const Color duskLightSurfaceSecondary = Color(0xFFEDE9E4);
  static const Color duskLightAccentPrimary = Color(0xFF4A3F8C); // deep indigo
  static const Color duskLightAccentCommitment = Color(0xFF1A1228);
  static const Color duskLightAccentCompletion = Color(0xFFC98A2E);
  static const Color duskLightTextPrimary = Color(0xFF1A1820);
  static const Color duskLightTextSecondary = Color(0xFF5C5570);

  // Dusk Dark
  static const Color duskDarkSurfacePrimary = Color(0xFF12101A);
  static const Color duskDarkSurfaceSecondary = Color(0xFF1E1B28);
  static const Color duskDarkAccentPrimary = Color(0xFF7B6FCC);
  static const Color duskDarkAccentCommitment = Color(0xFFEDE8F5);
  static const Color duskDarkAccentCompletion = Color(0xFFC98A2E);
  static const Color duskDarkTextPrimary = Color(0xFFEDE8F5);
  static const Color duskDarkTextSecondary = Color(0xFF9E94C0);

  // ─────────────────────────────────────────────────────────
  // Monochrome — Pure Greyscale
  // ─────────────────────────────────────────────────────────

  // Monochrome Light
  static const Color monochromeLightSurfacePrimary = Color(0xFFFFFFFF);
  static const Color monochromeLightSurfaceSecondary = Color(0xFFF0F0F0);
  static const Color monochromeLightAccentPrimary = Color(0xFF333333);
  static const Color monochromeLightAccentCommitment = Color(0xFF000000);
  static const Color monochromeLightAccentCompletion = Color(0xFF444444);
  static const Color monochromeLightTextPrimary = Color(0xFF111111);
  static const Color monochromeLightTextSecondary = Color(0xFF555555);

  // Monochrome Dark
  static const Color monochromeDarkSurfacePrimary = Color(0xFF111111);
  static const Color monochromeDarkSurfaceSecondary = Color(0xFF1E1E1E);
  static const Color monochromeDarkAccentPrimary = Color(0xFFDDDDDD);
  static const Color monochromeDarkAccentCommitment = Color(0xFFFFFFFF);
  static const Color monochromeDarkAccentCompletion = Color(0xFFCCCCCC);
  static const Color monochromeDarkTextPrimary = Color(0xFFEEEEEE);
  static const Color monochromeDarkTextSecondary = Color(0xFF999999);

  // ─────────────────────────────────────────────────────────
  // Shared semantic colours — stake zones & schedule health
  // ─────────────────────────────────────────────────────────

  static const Color stakeZoneLow = Color(0xFF6B9E78); // sage
  static const Color stakeZoneMid = Color(0xFFC98A2E); // amber
  static const Color stakeZoneHigh = Color(0xFFC4623A); // terracotta

  static const Color scheduleHealthy = Color(0xFF6B9E78);
  static const Color scheduleAtRisk = Color(0xFFC98A2E);
  static const Color scheduleCritical = Color(0xFFC4623A);
}
