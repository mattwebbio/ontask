import 'package:flutter/widgets.dart';

/// Named motion token constants for On Task (UX-DR20).
///
/// Only the tokens used in Story 3.7 are defined here:
/// - "The reveal" — sequential task appearance on initial list load
/// - "The plan shifts" — highlight animation on schedule-changed task rows
///
/// Epic 6 tokens ("The vault close", "The release") are NOT implemented here.
/// "The chapter break" was implemented separately in Story 2.13.
///
/// All durations are in milliseconds to remain framework-agnostic.
/// No animation logic lives here — only constants and the [isReducedMotion] helper.
class MotionTokens {
  MotionTokens._();

  // ── "The reveal" — sequential task appearance on initial load ─────────────

  /// Stagger delay between consecutive task rows in "The reveal" (ms).
  ///
  /// Each row starts its animation [revealStaggerMs] after the previous row.
  static const int revealStaggerMs = 50;

  /// Fade-in duration for each individual task row in "The reveal" (ms).
  static const int revealDurationMs = 300;

  // ── "The plan shifts" — highlight on schedule-changed rows ────────────────

  /// Duration of the colour-flash animation on changed task rows (ms).
  static const int planShiftsDurationMs = 400;
}

/// Returns true when the user has enabled "Reduce Motion" in iOS Accessibility.
///
/// Must be called inside a build method (or [didChangeDependencies]) where
/// [BuildContext] has a valid [MediaQuery] ancestor.
///
/// When true, all named motion tokens should produce instant state changes
/// with no movement or animation.
bool isReducedMotion(BuildContext context) =>
    MediaQuery.of(context).disableAnimations;
