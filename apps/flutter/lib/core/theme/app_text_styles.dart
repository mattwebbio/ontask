import 'package:flutter/material.dart';

/// Full type scale using theme-relative named constants.
///
/// CRITICAL: Widgets in feature layers MUST reference [AppTextStyles] constants
/// or [Theme.of(context).textTheme.*] — NEVER use literal fontSize values
/// (e.g., `fontSize: 17`) in widget trees.
///
/// Dynamic Type scaling is applied automatically by Flutter's text engine via
/// [MediaQuery.textScaler] — widgets must NOT call textScaler.scale() manually.
class AppTextStyles {
  AppTextStyles._();

  // ── System font (SF Pro on iOS — fontFamily: null uses system default) ──

  /// Hero task display — 28pt, semibold. Large text (≥22pt) for WCAG 3:1.
  static const TextStyle heroTask = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  /// Section heading — 22pt, bold. Large text (≥22pt) for WCAG 3:1.
  static const TextStyle sectionHeading = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  /// Body text — 17pt, regular. WCAG body text threshold (≥4.5:1 required).
  static const TextStyle body = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  /// Secondary / supporting text — 15pt, regular.
  static const TextStyle secondary = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  /// Caption / metadata text — 13pt, regular.
  static const TextStyle caption = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  // ── Serif font (New York on iOS / Playfair Display fallback) ──
  // fontFamily is null here; the resolved serif family is applied via copyWith
  // in AppTheme.buildTheme() using the FontConfig.serifFamily string.

  /// Voice-copy primary — 20pt, regular serif.
  static const TextStyle voiceCopyPrimary = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );

  /// Voice-copy secondary — 15pt, italic serif.
  static const TextStyle voiceCopySecondary = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.italic,
    height: 1.6,
  );

  /// Impact milestone — 34pt, regular serif. Large text for WCAG 3:1.
  static const TextStyle impactMilestone = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w400,
    height: 1.2,
  );
}
